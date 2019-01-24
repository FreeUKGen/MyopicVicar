# Encoding: UTF-8

Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'refinerycms-county_pages'
  s.author            = 'Ben W. Brumfield'
  s.version           = '1.4'
  s.description       = 'Ruby on Rails County Pages extension for Refinery CMS v 4'
  s.date              = '2018-03-28'
  s.summary           = 'County Pages extension for Refinery CMS'
  s.require_paths     = %w(lib)
  s.files             = Dir["{app,config,db,lib}/**/*"] + ["readme.md"]

  # Runtime dependencies
  s.add_dependency             'refinerycms-core'

  # Development dependencies (usually used for testing)
  s.add_development_dependency 'refinerycms-testing'
end
