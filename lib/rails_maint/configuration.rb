# frozen_string_literal: true

module RailsMaint
  class Configuration
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
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
