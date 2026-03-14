# service to create postems via freebmd1 perl api
# delegates postem creation to perl codebase to ensure single source of truth
# for postem logging, validation, and database updates

class FreebmdPostemService
  class PostemCreationError < StandardError; end
  class AuthenticationError < StandardError; end
  class ValidationError < StandardError; end

  def initialize
    @api_endpoint = ENV.fetch('FREEBMD_POSTEM_API_URL', 'https://www.freebmd.org.uk/api/create-postem.pl')
    @api_key = ENV.fetch('FREEBMD_API_KEY', nil)
    @timeout = 10 # seconds
  end

  # create a postem via freebmd1 perl api
  # @param record      [BestGuess] the bestguess record to attach postem to
  # @param information [String] the postem text (max 250 chars)
  # @param source_info [String] optional source information (e.g., ip address)
  # @param dry_run     [Boolean] if true, validate but don't create (returns 412)
  # @return            [Hash] response from api with :success, :message, :error, :dry_run
  def create_postem(record:, information:, source_info: nil, dry_run: false)
    validate_inputs!(record, information)

    database_name = get_database_name
    record_number = record.RecordNumber
    hash = get_record_hash(record)

    payload = {
      database: database_name,
      record_number: record_number,
      hash: hash,
      information: information.to_s.strip[0, 250], # truncate to max length
      source_info: source_info || '',
      dry_run: dry_run
    }

    response = call_api(payload)

    # handle dry-run response (412)
    if response[:dry_run]
      Rails.logger.info("Dry-run postem validation passed for record #{record_number}")
      return response
    end

    if response[:success]
      response
    else
      raise ValidationError, response[:error] if response[:code] == 422
      raise PostemCreationError, response[:error]
    end
  rescue Timeout::Error
    raise PostemCreationError, 'API request timed out'
  rescue StandardError => e
    Rails.logger.error("FreeBMD Postem API error: #{e.message}")
    raise
  end

  private

  def validate_inputs!(record, information)
    raise ArgumentError, 'record cannot be nil' unless record
    raise ArgumentError, 'information cannot be blank' if information.blank?
    raise ArgumentError, 'information must contain at least one space' unless information.to_s =~ /\s/
    raise ArgumentError, 'information too long (max 250 chars)' if information.to_s.length > 250
  end

  def get_database_name
    Postem.connection.current_database
  end

  def get_record_hash(record)
    # use bestguesshash table if available
    best_guess_hash = record.best_guess_hash
    return best_guess_hash.Hash if best_guess_hash.present?

    # fallback: compute hash manually (should match perl logic)
    record.record_hash
  end

  def call_api(payload)
    require 'net/http'
    require 'json'

    uri = URI(@api_endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = @timeout
    http.read_timeout = @timeout

    request = Net::HTTP::Post.new(uri.path, {
      'Content-Type' => 'application/json',
      'X-FreeBMD-API-Key' => @api_key
    })
    request.body = payload.to_json

    response = http.request(request)

    case response.code.to_i
    when 200
      JSON.parse(response.body, symbolize_names: true)
    when 401
      raise AuthenticationError, 'Invalid API key'
    when 404
      raise PostemCreationError, 'Record not found in FreeBMD database'
    when 412
      # dry-run mode: validation passed but not created
      JSON.parse(response.body, symbolize_names: true)
    when 422
      # validation error from perl api
      data = JSON.parse(response.body, symbolize_names: true)
      { success: false, error: data[:error], code: 422 }
    else
      data = JSON.parse(response.body, symbolize_names: true) rescue {}
      raise PostemCreationError, "API error (#{response.code}): #{data[:error] || response.body}"
    end
  rescue JSON::ParserError => e
    raise PostemCreationError, "Invalid API response: #{e.message}"
  end

  # dead code - don't alter the BestGuess postem flag ourselves - the cron will do it
  def set_postem_flag_on_record(record)
    raise PostemCreationError, "Not updating local Postem flag"

    new_confirmed = (record.Confirmed.to_i | BestGuess::ENTRY_POSTEM)
    record.update_column(:Confirmed, new_confirmed)

    # also update marriage record if present
    marriage = BestGuessMarriage.find_by(RecordNumber: record.RecordNumber)
    marriage&.update_column(:Confirmed, (marriage.Confirmed.to_i | BestGuess::ENTRY_POSTEM))
  rescue => e
    Rails.logger.warn("Failed to update Confirmed flag locally: #{e.message}")
    # non-fatal: perl's updatepostems.pl cron will fix it within 24 hours
  end
end
