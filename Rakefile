# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

begin
  require 'gemika/tasks'
rescue LoadError
  puts 'Run `gem install gemika` for additional tasks'
end

task default: ['matrix:spec', 'rubocop']
