namespace :ads_txt do
  desc 'Pull the hosted ads.txt from Publift Fuse and update the FreeBMD site copies'
  task pull: :environment do
    unless MyopicVicar::Application.config.template_set == MyopicVicar::TemplateSet::FREEBMD
      puts 'ads_txt:pull skipped - only FreeBMD serves ads.txt via Publift Fuse'
      next
    end

    account_id = ENV['PUBLIFT_ACCOUNT_ID'] || '01GVF7JDNG2YS5MGQ2VNV63ZEN'
    source_url = "https://cdn.fuseplatform.net/ads-txt/publift/#{account_id}/ads.txt"

    site_specific_path = Rails.root.join('public_site_specific', 'freebmd', 'ads.txt')
    live_path = Rails.root.join('public', 'ads.txt')

    require 'net/http'
    require 'tempfile'

    response = Net::HTTP.get_response(URI(source_url))
    unless response.is_a?(Net::HTTPSuccess)
      abort "ads_txt:pull failed - GET #{source_url} returned #{response.code} #{response.message}"
    end

    body = response.body.to_s
    if body.strip.empty? || !body.include?('publift.com')
      abort "ads_txt:pull failed - response from #{source_url} did not look like a valid ads.txt, aborting without overwriting existing files"
    end

    [site_specific_path, live_path].each do |destination|
      Tempfile.create('ads.txt', destination.dirname.to_s) do |tmp|
        tmp.write(body)
        tmp.flush
        FileUtils.mv(tmp.path, destination.to_s)
        FileUtils.chmod(0o644, destination.to_s)
      end
    end

    puts "ads_txt:pull updated #{site_specific_path} and #{live_path} from #{source_url} (#{body.bytesize} bytes)"
  end
end
