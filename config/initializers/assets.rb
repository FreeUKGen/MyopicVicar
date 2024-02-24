# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
# Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Enable the asset pipeline

Rails.application.configure do
  config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

  config.assets.precompile += %w[styles/scss/lap_and_up.scss]
  config.assets.precompile += %w[styles/scss/palm.scss]
  config.assets.precompile += %w[styles/scss/ladda.scss]
  config.assets.precompile += %w[styles/css/donate_icon.css]
  config.assets.precompile += %w[styles/css/icons.data.svg.css]
  config.assets.precompile += %w[styles/css/freereg_content.css]
  config.assets.precompile += %w[prebid_ads.js]
  config.assets.precompile += %w( javascripts/freecen_gdpr.js )
  config.assets.precompile += %w[jquery.min.js]
  config.assets.precompile += %w[jquery.chained.remote.js]
  config.assets.precompile += %w[jquery.cookiesDirective.js]
  config.assets.precompile += %w[html5shiv.js]
  config.assets.precompile += %w[spin.min.js]
  config.assets.precompile += %w[ladda.min.js]
  config.assets.precompile += %w[ads.js]
  config.assets.precompile += %w[adsbygoogle.js]
  config.assets.precompile += %w[prebid_ads.js]
  config.assets.precompile += %w[freecen_coverage_graph.js]
  config.assets.precompile += %w[styles/css/donate_icon.css]
  config.assets.precompile += %w[cookie_control.js]
  config.assets.precompile += %w[advert_control.js]
 # config.assets.precompile += %w( javascripts/freereg_fuse_tag.js )
  #config.assets.precompile += %w( javascripts/freecen_fuse_tag.js )
end
