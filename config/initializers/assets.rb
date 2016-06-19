# Enable the asset pipeline

# Version of your assets, change this if you want to expire all your assets

Rails.application.configure do
  config.assets.paths << Rails.root.join("app", "assets", "fonts")
  config.assets.paths << Rails.root.join("app", "assets", "images")
  config.assets.paths << Rails.root.join("app", "assets", "images","png")
  config.assets.paths << Rails.root.join("app", "assets", "images","svg","min")
  config.assets.paths << Rails.root.join("app", "assets", "images","svg","src")
  config.assets.precompile += %w(  styles/css/lap_and_up.min.css )
  config.assets.precompile += %w(  styles/css/ie.min.css )
  config.assets.precompile += %w(  styles/css/icons.data.svg.css )
  config.assets.precompile += %w(  styles/css/icons.data.png.css )
  config.assets.precompile += %w(  styles/css/icons.fallback.css )
  config.assets.precompile += %w( styles/css/freereg_content.css )
  config.assets.precompile += %w( styles/css/ladda.min.css )
  config.assets.precompile += %w( styles/css/palm.min.css )
  config.assets.precompile += %w( jquery.min.js  )
  config.assets.precompile += %w( jquery.chained.remote.js  )
  config.assets.precompile += %w( jquery.cookiesDirective.js  )
  config.assets.precompile += %w( html5shiv.js )
  config.assets.precompile += %w( spin.min.js)
  config.assets.precompile += %w( ladda.min.js)


end
