# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'middleman-google_drive/version'

Gem::Specification.new do |spec|
  spec.name          = 'middleman-google_drive'
  spec.version       = Middleman::GoogleDrive::VERSION
  spec.authors       = ['Ryan Mark', 'Pablo Mercado']
  spec.email         = ['ryan@mrk.cc', 'pablo@voxmedia.com']
  spec.summary       = 'Pull content from a google spreadsheet to use in your middleman site.'
  #spec.description   = %q(TODO: Write a longer description. Optional.)
  spec.homepage      = 'https://github.com/voxmedia/middleman-google_drive'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'middleman-core', ['>= 3.0.0']
  spec.add_runtime_dependency 'google-api-client', '>= 0.7.1'
  spec.add_runtime_dependency 'google_drive'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
