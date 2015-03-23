# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'middleman-google_drive/version'

Gem::Specification.new do |spec|
  spec.name          = 'middleman-google_drive'
  spec.version       = Middleman::GoogleDrive::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Ryan Mark', 'Pablo Mercado']
  spec.email         = ['ryan@mrk.cc', 'pablo@voxmedia.com']
  spec.summary       = 'Pull content from a google spreadsheet to use in your middleman site.'
  #spec.description   = %q(TODO: Write a longer description. Optional.)
  spec.homepage      = 'https://github.com/voxmedia/middleman-google_drive'
  spec.license       = 'BSD'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.1'

  spec.add_runtime_dependency 'middleman-core', '~> 3'
  spec.add_runtime_dependency 'retriable', '~> 1.4'
  spec.add_runtime_dependency 'google-api-client', '< 0.8'
  spec.add_runtime_dependency 'rubyXL', '~> 3.3'
  spec.add_runtime_dependency 'archieml', '~> 0.1'
  spec.add_runtime_dependency 'mime-types', '~> 2.4'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'minitest', '~> 5.4'
  spec.add_development_dependency 'yard', '~> 0.8'
end
