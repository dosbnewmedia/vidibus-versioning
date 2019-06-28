# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'vidibus/versioning/_version'

Gem::Specification.new do |s|
  s.name        = 'vidibus-versioning'
  s.version     = Vidibus::Versioning::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Andre Pankratz'
  s.email       = 'andre@vidibus.com'
  s.homepage    = 'https://github.com/vidibus/vidibus-versioning'
  s.summary     = 'Advanced versioning for Mongoid models'
  s.description = 'Versioning designed for advanced usage, like scheduling versions.'
  s.license     = 'MIT'

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project         = 'vidibus-versioning'

  s.add_dependency 'mongoid', '>=5.0', '<7'
  s.add_dependency 'vidibus-core_extensions'
  s.add_dependency 'vidibus-uuid', "1.0.0"

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'database_cleaner'

  s.files = Dir.glob('{lib,app,config}/**/*') + %w[LICENSE README.md Rakefile]
  s.require_path = 'lib'
end
