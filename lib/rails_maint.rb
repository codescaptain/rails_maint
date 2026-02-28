# frozen_string_literal: true

require 'rails_maint/version'
require_relative 'rails_maint/configuration'
require_relative 'rails_maint/config_loader'
require_relative 'rails_maint/errors'
require_relative 'rails_maint/instrumentation'
require_relative 'rails_maint/path_matcher'
require_relative 'rails_maint/schedule'
require_relative 'rails_maint/webhook'
require_relative 'rails_maint/middleware'
require_relative 'rails_maint/cli'

module RailsMaint
  class << self
    attr_writer :logger

    def logger
      @logger ||= default_logger
    end

    private

    def default_logger
      require 'logger'
      Logger.new($stdout, level: Logger::INFO)
    end
  end
end

require 'rails_maint/railtie' if defined?(Rails::Railtie)
