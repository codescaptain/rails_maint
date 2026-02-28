# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

begin
  require 'bundler/audit/task'
  Bundler::Audit::Task.new
rescue LoadError
  desc 'bundler-audit not available'
  task :'bundle:audit' do
    abort 'bundler-audit is not installed. Run: gem install bundler-audit'
  end
end

task default: %i[spec rubocop]
