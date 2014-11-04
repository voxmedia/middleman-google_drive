require 'bundler/gem_tasks'
require 'bundler/setup'
require 'rake/testtask'
require 'rake/clean'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/*_test.rb']
end

desc 'Run tests'
task default: :test
