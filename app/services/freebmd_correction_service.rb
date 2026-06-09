# Submits FreeBMD2 Data Problem reports to FreeBMD1 correctionslog via create-correction.pl API.

class FreebmdCorrectionService
  class CorrectionSubmissionError < StandardError; end
  class AuthenticationError < StandardError; end
  class ValidationError < StandardError; end

  def initialize
    require 'timeout'
    @api_endpoint = ENV.fetch('FREEBMD_CORRECTION_API_URL', 'https://www.freebmd.org.uk/api/create-correction.pl')
    @api_key = ENV.fetch('FREEBMD_API_KEY', nil)
    @timeout = 15
  end

  # @param contact [Contact] saved Data Problem contact with record_id
  # @param dry_run [Boolean]
  # @return [Hash] :success, :message, optional :error, :dry_run
  def submit(contact:, dry_run: false)
    validate_contact!(contact)

    payload = FreebmdCorrectionPayload.build(contact)
    payload[:dry_run] = true if dry_run

    if payload[:corrections].blank? && payload[:corrections_text].blank? && !payload[:missing]
      return { success: false, skipped: true, message: 'No corrections to submit to FreeBMD1' }
    end

    response = call_api(payload)

    if response[:dry_run]
      Rails.logger.info("FreeBMD correction dry-run OK for contact #{contact.id}")
      return response.merge(success: true)
    end

    if response[:success]
      Rails.logger.info("FreeBMD correction logged for contact #{contact.id}, record #{payload[:record_number]}")
      response
    else
      raise ValidationError, response[:error] if response[:code] == 422
      raise CorrectionSubmissionError, response[:error] || 'Unknown API error'
    end
  rescue Timeout::Error
    raise CorrectionSubmissionError, 'FreeBMD1 correction API timed out'
  rescue ValidationError, AuthenticationError, CorrectionSubmissionError
    raise
  rescue StandardError => e
    Rails.logger.error("FreeBMD correction API error: #{e.message}")
    raise CorrectionSubmissionError, e.message
  end

  private

  def validate_contact!(contact)
    raise ValidationError, 'contact is required' unless contact
    raise ValidationError, 'record_id is required' if contact.record_id.blank?
    raise ValidationError, 'email is required' if contact.email_address.blank?
  end

  def call_api(payload)
    require 'uri'
    require 'net/http'
    require 'json'

    uri = URI(@api_endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = @timeout
    http.read_timeout = @timeout

    headers = { 'Content-Type' => 'application/json' }
    headers['X-FreeBMD-API-Key'] = @api_key if @api_key.present?

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = api_payload_json(payload)

    response = http.request(request)

    case response.code.to_i
    when 200
      JSON.parse(response.body, symbolize_names: true)
    when 401
      raise AuthenticationError, 'Invalid API key'
    when 404
      raise CorrectionSubmissionError, 'Record not found in FreeBMD1 database'
    when 412
      JSON.parse(response.body, symbolize_names: true).merge(dry_run: true)
    when 400, 422
      data = JSON.parse(response.body, symbolize_names: true) rescue {}
      { success: false, error: data[:error] || response.body, code: response.code.to_i }
    else
      data = JSON.parse(response.body, symbolize_names: true) rescue {}
      raise CorrectionSubmissionError, "API error (#{response.code}): #{data[:error] || response.body}"
    end
  rescue JSON::ParserError => e
    raise CorrectionSubmissionError, "Invalid API response: #{e.message}"
  end

  def api_payload_json(payload)
    body = payload.dup
    if body[:corrections].present?
      body.delete(:corrections_text)
    else
      body.delete(:corrections)
    end
    body.to_json
  end
end
