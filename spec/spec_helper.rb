# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/generators/'
  enable_coverage :branch
  minimum_coverage 80
end

require 'bundler/setup'
require 'logger'
require 'rails_maint'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    RailsMaint.logger = Logger.new(File::NULL)
  end

  config.after do
    RailsMaint.reset_configuration!
    RailsMaint.logger = Logger.new(File::NULL)
  end
end
