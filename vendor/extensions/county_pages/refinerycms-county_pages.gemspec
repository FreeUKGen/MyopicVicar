# Encoding: UTF-8

Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'refinerycms-county_pages'
  s.author            = 'Ben W. Brumfield'
  s.version           = '1.3'
  s.description       = 'Ruby on Rails County Pages extension for Refinery CMS'
  s.date              = '2016-12-23'
  s.summary           = 'County Pages extension for Refinery CMS'
  s.require_paths     = %w(lib)
  s.files             = Dir["{app,config,db,lib}/**/*"] + ["readme.md"]

  # Runtime dependencies
  s.add_dependency             'refinerycms-core'

  # Development dependencies (usually used for testing)
  s.add_development_dependency 'refinerycms-testing'
end
