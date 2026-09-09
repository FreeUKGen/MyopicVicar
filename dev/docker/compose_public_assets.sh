#!/usr/bin/env bash
set -euo pipefail

cd /app

rm -rf public/images public/stylesheets public/javascripts
mkdir -p public/images
mkdir -p public/stylesheets
mkdir -p public/javascripts

bundle exec rails runner - <<'RUBY'
require 'fileutils'

environment = Rails.application.assets || Sprockets::Railtie.build_environment(Rails.application)

assets = {
  'application.css' => 'application.css',
  'styles/css/donate_icon.css' => 'styles/css/donate_icon.css',
  'styles/css/icons.data.svg.css' => 'styles/css/icons.data.svg.css',
  'styles/css/freereg_content.css' => 'styles/css/freereg_content.css',
  'styles/scss/palm.css' => 'styles/scss/palm.css',
  'styles/scss/lap_and_up.css' => 'styles/scss/lap_and_up.css',
  'styles/scss/ladda.css' => 'styles/scss/ladda.css'
}

assets.each do |logical_path, output_path|
  asset = environment.find_asset(logical_path)
  raise "Missing asset #{logical_path}" unless asset

  destination = Rails.root.join('public', 'stylesheets', output_path)
  FileUtils.mkdir_p(File.dirname(destination))
  File.binwrite(destination, asset.to_s)
  puts "wrote #{destination.relative_path_from(Rails.root)}"
end

scripts = {
  'application.js' => 'application.js',
  'jquery.min.js' => 'jquery.min.js',
  'jquery.chained.remote.js' => 'jquery.chained.remote.js',
  'cookie_control.js' => 'cookie_control.js',
  'jquery.cookiesDirective.js' => 'jquery.cookiesDirective.js',
  'spin.min.js' => 'spin.min.js',
  'ladda.min.js' => 'ladda.min.js',
  'freecen_coverage_graph.js' => 'freecen_coverage_graph.js',
  'javascripts/freereg_fuse_tag.js' => 'javascripts/freereg_fuse_tag.js'
}

scripts.each do |logical_path, output_path|
  asset = environment.find_asset(logical_path)
  raise "Missing asset #{logical_path}" unless asset

  destination = Rails.root.join('public', 'javascripts', output_path)
  FileUtils.mkdir_p(File.dirname(destination))
  File.binwrite(destination, asset.to_s)
  puts "wrote #{destination.relative_path_from(Rails.root)}"
end
RUBY

cp -R app/assets/images/. public/images/
echo "copied public/images"
