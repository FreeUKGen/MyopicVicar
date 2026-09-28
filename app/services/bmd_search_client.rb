# frozen_string_literal: true

# Calls the FreeBMD cross-project search API (pilot) from FreeREG.
# Deliberately fails soft: any problem here must never break the FreeREG
# results page. On any error, timeout, or bad response it logs and returns
# an empty array rather than raising.
class BmdSearchClient
  DEFAULT_TIMEOUT = 5 # seconds - keep short, this must not stall FreeREG's own results page

  def initialize
    @api_base_url = ENV.fetch('BMD_SEARCH_API_URL', nil)
    @api_token = ENV.fetch('BMD_API_TOKEN', nil)
  end

  # @param surname     [String] required
  # @param first_name  [String] optional
  # @param year        [Integer, String] optional
  # @param county      [String] optional - a chapman code, e.g. "DEV"
  # @return [Array<Hash>] business objects from the FreeBMD API, or [] on any failure
  def search(surname:, first_name: nil, year: nil, county: nil)
    return [] if @api_base_url.blank? || surname.blank?

    params = { surname: surname }
    params[:first_name] = first_name if first_name.present?
    params[:year] = year if year.present?
    params[:county] = county if county.present?

    response = call_api(params)
    return [] unless response

    Array(response[:results])
  rescue StandardError => e
    Rails.logger.warn("BmdSearchClient: unexpected error: #{e.class}: #{e.message}")
    []
  end

  private

  def call_api(params)
    require 'net/http'
    require 'json'
    require 'uri'

    uri = URI(@api_base_url)
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = DEFAULT_TIMEOUT
    http.read_timeout = DEFAULT_TIMEOUT

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{@api_token}" if @api_token.present?

    response = http.request(request)

    unless response.code.to_i == 200
      Rails.logger.warn("BmdSearchClient: API returned #{response.code} for #{uri.request_uri}")
      return nil
    end

    JSON.parse(response.body, symbolize_names: true)
  rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn("BmdSearchClient: timed out: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.warn("BmdSearchClient: invalid JSON response: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.warn("BmdSearchClient: request failed: #{e.class}: #{e.message}")
    nil
  end
end
