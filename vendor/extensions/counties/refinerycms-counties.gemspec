# Encoding: UTF-8

Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'refinerycms-counties'
  s.version           = '1.0'
  s.description       = 'Ruby on Rails Counties extension for Refinery CMS'
  s.date              = '2014-03-19'
  s.author            = 'Ben W Brumfield'
  s.summary           = 'Counties extension for Refinery CMS'
  s.require_paths     = %w(lib)
  s.files             = Dir["{app,config,db,lib}/**/*"] + ["readme.md"]

  # Runtime dependencies
  s.add_dependency             'refinerycms-core',    '~> 2.1.1'

  # Development dependencies (usually used for testing)
  s.add_development_dependency 'refinerycms-testing', '~> 2.1.1'
end
