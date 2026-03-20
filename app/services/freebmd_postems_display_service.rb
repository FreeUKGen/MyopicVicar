class FreebmdPostemsDisplayService
  class PostemsUnavailableError < StandardError; end
  class PostemDisplayError < StandardError; end

  def initialize
    @api_key = ENV.fetch('FREEBMD_API_KEY', nil)
    @timeout = 10 # seconds

    @api_endpoint =
      ENV['FREEBMD_POSTEMS_DISPLAY_API_URL'].presence ||
      derive_display_url(ENV['FREEBMD_POSTEM_API_URL'])

    if @api_endpoint.blank? || @api_endpoint !~ /display-postems\.pl\z/i
      raise PostemDisplayError,
            'FREEBMD_POSTEMS_DISPLAY_API_URL must point to .../api/display-postems.pl ' \
            '(or set FREEBMD_POSTEM_API_URL to a .../api/create-postem.pl URL so we can derive it)'
    end
  end

  # Fetch postems (read-only) via the FreeBMD1 Perl API.
  #
  # @param database [String] FreeBMD database name (e.g. bmd_123...)
  # @param hash [String] 22-char base64 record hash
  # @param include_html [Boolean] whether to include information_html from Perl logic
  # @return [Array<Hash>] array of postem items
  def fetch_postems(database:, hash:, include_html: false)
    payload = {
      database: database,
      hash: hash,
      include_html: include_html
    }

    response = call_api(payload)
    response[:postems] || []
  end

  private

  def derive_display_url(create_url)
    return if create_url.blank?
    create_url.to_s.sub(/create-postem\.pl/i, 'display-postems.pl')
  end

  def call_api(payload)
    require 'net/http'
    require 'json'

    uri = URI(@api_endpoint.to_s.strip)
    if uri.host.blank?
      raise PostemDisplayError, 'FREEBMD_POSTEMS_DISPLAY_API_URL is not a valid URL'
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = @timeout
    http.read_timeout = @timeout

    headers = { 'Content-Type' => 'application/json' }
    headers['X-FreeBMD-API-Key'] = @api_key if @api_key.present?

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = payload.to_json

    response = http.request(request)
    code = response.code.to_i
    body = response.body.to_s

    data =
      JSON.parse(body, symbolize_names: true)

    case code
    when 200
      data
    when 503
      raise PostemsUnavailableError, data[:error] || 'Postems are only available from the master server.'
    when 401
      raise PostemDisplayError, data[:error] || 'Unauthorized. Valid API key required.'
    else
      raise PostemDisplayError, data[:error] || "API error (#{code})"
    end
  rescue JSON::ParserError
    raise PostemDisplayError, "API returned non-JSON response (HTTP #{code}): #{body.byteslice(0, 200)}"
  end
end

