# frozen_string_literal: true

require 'yaml'
require_relative 'helpers/maintenance_page_helper'

module RailsMaint
  class Middleware
    include MaintenancePageHelper

    def initialize(app)
      @app = app
    end

    def call(env)
      if maintenance_mode_enabled? && !ip_whitelisted?(env)
        [503, { 'Content-Type' => 'text/html' }, [maintenance_page]]
      else
        @app.call(env)
      end
    end

    private

    def maintenance_mode_enabled?
      File.exist?('tmp/maintenance_mode.txt')
    end

    def ip_whitelisted?(env)
      config = load_config
      white_listed_ips = config['white_listed_ips'] || []
      client_ip = env['REMOTE_ADDR']
      white_listed_ips.include?(client_ip)
    end

    def load_config
      config_path = 'config/rails_maint.yml'
      if File.exist?(config_path)
        YAML.safe_load_file(config_path, permitted_classes: [])
      else
        {}
      end
    end

    def maintenance_page
      config = load_config
      locale = config['locale'] || 'en'
      default_maintenance_page_content(locale)
    end
  end
end
