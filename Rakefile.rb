#!/usr/bin/env ruby

require_relative 'lib/ffi-wingui-core/common'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList[
    'test/*_test.rb'
  ]
end

desc 'Build gem'
task :build => [:test] do |t|
  system "gem build ffi-wingui-core.gemspec"
end

desc 'Push gem'
task :push => [:build] do |t|
  system "gem push ffi-wingui-core-#{WinGUI::VERSION}.gem"
end

task :default => [:test]

if __FILE__ == $0
  Rake::Task[:default].invoke
end
