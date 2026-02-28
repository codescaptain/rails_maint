# frozen_string_literal: true

require 'yaml'
require_relative 'helpers/maintenance_page_helper'
require_relative 'config_loader'

module RailsMaint
  class Middleware
    include MaintenancePageHelper

    def initialize(app)
      @app = app
    end

    def call(env)
      if maintenance_active? && !ip_whitelisted?(env) && !path_bypassed?(env) && path_affected?(env)
        [503, response_headers, [maintenance_page]]
      else
        @app.call(env)
      end
    end

    private

    def maintenance_active?
      path = effective_config(:maintenance_file_path, 'maintenance_file_path', 'tmp/maintenance_mode.txt')
      return false unless File.exist?(path)

      schedule = RailsMaint::Schedule.load(path)
      schedule.active?
    end

    def ip_whitelisted?(env)
      yaml_ips = yaml_config['white_listed_ips'] || []
      dsl_ips = RailsMaint.configuration.white_listed_ips || []
      white_listed_ips = (yaml_ips + dsl_ips).uniq
      client_ip = env['REMOTE_ADDR']
      white_listed_ips.include?(client_ip)
    end

    def path_bypassed?(env)
      bypass = effective_array_config(:bypass_paths, 'bypass_paths')
      return false if bypass.empty?

      request_path = env['PATH_INFO'] || '/'
      bypass.any? { |pattern| path_matches?(pattern, request_path) }
    end

    def path_affected?(env)
      maintenance = effective_array_config(:maintenance_paths, 'maintenance_paths')
      return true if maintenance.empty?

      request_path = env['PATH_INFO'] || '/'
      maintenance.any? { |pattern| path_matches?(pattern, request_path) }
    end

    def path_matches?(pattern, request_path)
      if pattern.end_with?('/*')
        prefix = pattern.chomp('/*')
        request_path.start_with?(prefix)
      else
        request_path == pattern
      end
    end

    def response_headers
      retry_value = effective_config(:retry_after, 'retry_after', 3600)

      path = effective_config(:maintenance_file_path, 'maintenance_file_path', 'tmp/maintenance_mode.txt')
      if File.exist?(path)
        schedule = RailsMaint::Schedule.load(path)
        remaining = schedule.seconds_until_end
        retry_value = remaining if remaining
      end

      {
        'Content-Type' => 'text/html',
        'Retry-After' => retry_value.to_s
      }
    end

    def yaml_config
      @yaml_config ||= ConfigLoader.load
    end

    def maintenance_page
      custom_path = effective_config(:custom_page_path, 'custom_page', nil)

      if custom_path && serve_custom_page?(custom_path)
        File.read(custom_path)
      else
        config = yaml_config
        locale = config['locale'] || RailsMaint.configuration.locale || 'en'
        default_maintenance_page_content(locale)
      end
    end

    def serve_custom_page?(path)
      return false unless File.exist?(path)

      expanded = File.expand_path(path)
      app_root = File.expand_path('.')
      expanded.start_with?(app_root)
    end

    def effective_config(dsl_key, yaml_key, default)
      yaml_val = yaml_config[yaml_key]
      dsl_val = RailsMaint.configuration.public_send(dsl_key)
      dsl_default = Configuration.new.public_send(dsl_key)

      if yaml_val
        yaml_val
      elsif dsl_val != dsl_default
        dsl_val
      else
        default
      end
    end

    def effective_array_config(dsl_key, yaml_key)
      yaml_val = yaml_config[yaml_key]
      dsl_val = RailsMaint.configuration.public_send(dsl_key)
      yaml_arr = Array(yaml_val)
      dsl_arr = Array(dsl_val)
      (yaml_arr + dsl_arr).uniq
    end
  end
end
