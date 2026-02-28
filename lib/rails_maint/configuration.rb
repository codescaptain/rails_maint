# frozen_string_literal: true

require 'uri'

module RailsMaint
  class Configuration
    ALLOWED_LOCALE_PATTERN = /\A[a-z]{2}(-[A-Z]{2})?\z/

    attr_accessor :locale, :white_listed_ips, :maintenance_file_path,
                  :custom_page_path, :config_file_path, :retry_after,
                  :bypass_paths, :maintenance_paths, :webhook_url

    def initialize
      @locale = 'en'
      @white_listed_ips = []
      @maintenance_file_path = 'tmp/maintenance_mode.txt'
      @custom_page_path = nil
      @config_file_path = 'config/rails_maint.yml'
      @retry_after = 3600
      @bypass_paths = []
      @maintenance_paths = []
      @webhook_url = nil
    end

    def validate!
      validate_locale!
      validate_retry_after!
      validate_webhook_url!
    end

    private

    def validate_locale!
      return if locale.nil?
      return if locale.to_s.match?(ALLOWED_LOCALE_PATTERN)

      raise InvalidLocaleError, "Invalid locale format: #{locale.inspect}. Expected format: 'en' or 'en-US'"
    end

    def validate_retry_after!
      return if retry_after.nil?
      return if retry_after.is_a?(Numeric) && retry_after.positive?

      raise InvalidConfigurationError, "retry_after must be a positive number, got: #{retry_after.inspect}"
    end

    def validate_webhook_url!
      return if webhook_url.nil? || webhook_url.empty?

      uri = URI.parse(webhook_url)
      return if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      raise InvalidConfigurationError, "webhook_url must be a valid HTTP(S) URL, got: #{webhook_url.inspect}"
    rescue URI::InvalidURIError
      raise InvalidConfigurationError, "webhook_url is not a valid URI: #{webhook_url.inspect}"
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
      configuration.validate!
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
