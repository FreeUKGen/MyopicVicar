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
    @allowed_hosts = parse_allowed_hosts(ENV['FREEBMD_POSTEM_ALLOWED_HOSTS'])
    @timeout = postem_http_timeout_seconds
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

  def postem_http_timeout_seconds
    t = ENV['FREEBMD_POSTEM_HTTP_TIMEOUT'].to_s.strip
    return 10 if t.blank?
    n = t.to_i
    n.positive? ? n : 10
  end

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

    uri = URI(@api_endpoint.to_s.strip)
    validate_api_endpoint!(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = @timeout
    http.read_timeout = @timeout

    headers = { 'Content-Type' => 'application/json' }
    if @api_key.present?
      api_key = @api_key.to_s
      if api_key.match?(/[\r\n]/)
        raise PostemCreationError, 'FREEBMD_API_KEY contains invalid characters'
      end
      headers['X-FreeBMD-API-Key'] = api_key
    end

    request_path = uri.path.to_s.sub(%r{/+\z}, '')
    request = Net::HTTP::Post.new(request_path, headers)
    # FreeBMD1 API scripts expect the JSON payload in the request body.
    request.body = payload.to_json

    response = http.request(request)
    code = response.code.to_i
    body = response.body.to_s

    case code
    when 200
      parse_json_body!(body, code)
    when 401
      raise AuthenticationError, 'Invalid API key'
    when 404
      raise PostemCreationError, 'Record not found in FreeBMD database'
    when 412
      # dry-run mode: validation passed but not created
      parse_json_body!(body, code)
    when 422
      # validation error from perl api
      data = parse_json_body!(body, code)
      { success: false, error: data[:error], code: 422 }
    else
      if html_response?(body)
        raise PostemCreationError, non_json_api_endpoint_message
      end
      data = parse_json_body!(body, code)
      detail = data[:error].presence || data[:message].presence || body.to_s.truncate(500)
      raise PostemCreationError, "API error (#{code}): #{detail}"
    end
  end

  def html_response?(raw)
    raw.lstrip.match?(/\A<!DOCTYPE|<html[\s>]/i)
  end

  # Server returned a web page (e.g. FreeBMD home) instead of the JSON API — wrong URL or redirect
  def non_json_api_endpoint_message
    'The postem API URL is not a valid URL (e.g. .../api/create-postem.pl), not the site home page.'
  end

  def parse_json_body!(body, http_code)
    if html_response?(body)
      Rails.logger.error("Postem API URL returned HTML (HTTP #{http_code}), body preview: #{body.byteslice(0, 300).inspect}")
      raise PostemCreationError, non_json_api_endpoint_message
    end
    JSON.parse(body, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error("Postem API JSON parse error (HTTP #{http_code}): #{e.message}; body preview: #{body.byteslice(0, 500).inspect}")
    snippet = body.to_s.squish.truncate(400)
    raise PostemCreationError,
      "Postem API returned non-JSON (HTTP #{http_code}): #{snippet}. " \
      'If you see HTML or a site home page, set FREEBMD_POSTEM_API_URL to the full path …/api/create-postem.pl.'
  end

  def validate_api_endpoint!(uri)
    if uri.host.blank? || uri.scheme.blank?
      raise PostemCreationError, 'FREEBMD_POSTEM_API_URL is not a valid URL'
    end

    unless %w[http https].include?(uri.scheme)
      raise PostemCreationError, 'FREEBMD_POSTEM_API_URL must use http or https'
    end

    expected_path = %r{\A/api/create-postem\.pl/?\z}i
    unless uri.path.to_s.match?(expected_path)
      raise PostemCreationError,
            'FREEBMD_POSTEM_API_URL must point to .../api/create-postem.pl'
    end

    if uri.query.present?
      raise PostemCreationError, 'FREEBMD_POSTEM_API_URL must not include a query string'
    end

    if @allowed_hosts.any? && !@allowed_hosts.include?(uri.host)
      raise PostemCreationError, 'FREEBMD_POSTEM_API_URL host is not allowed'
    end
  end

  def parse_allowed_hosts(value)
    return [] if value.blank?
    value.to_s.split(',').map(&:strip).reject(&:blank?)
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
