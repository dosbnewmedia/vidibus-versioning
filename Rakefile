require 'bundler'
require 'rdoc/task'
require 'rspec'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'vidibus/versioning/_version'

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "vidibus-versioning #{Vidibus::Versioning::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << '--charset=utf-8'
end
