# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc 'Run tests'
task default: %i[install test]

desc 'Install dependencies'
task :install do
  system('bundle install')
end
