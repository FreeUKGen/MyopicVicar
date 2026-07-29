require 'net/http'
require 'uri'

# Checks whether an outside (third-party) URL currently returns a successful HTTP
# response, so views can avoid presenting dead/unreachable links to users.
# See FreeCENMigration issue #1936.
class OutsideLinkChecker
  TIMEOUT = 3 # seconds; keeps page-render latency bounded for a live, synchronous check

  def self.reachable?(url)
    uri = URI.parse(url.to_s.strip)
    return false unless uri.is_a?(URI::HTTP) && uri.host.present?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    path = uri.request_uri.presence || '/'
    response = http.request_head(path)
    # Some servers reject HEAD; fall back to GET before concluding the link is dead.
    response = http.request_get(path) if response.is_a?(Net::HTTPMethodNotAllowed)

    response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
  rescue StandardError
    false
  end
end
