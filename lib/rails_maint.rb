# frozen_string_literal: true

require 'rails_maint/version'
require_relative 'rails_maint/configuration'
require_relative 'rails_maint/config_loader'
require_relative 'rails_maint/schedule'
require_relative 'rails_maint/webhook'
require_relative 'rails_maint/middleware'
require_relative 'rails_maint/cli'

module RailsMaint
  class Error < StandardError; end
end

require 'rails_maint/railtie' if defined?(Rails::Railtie)
