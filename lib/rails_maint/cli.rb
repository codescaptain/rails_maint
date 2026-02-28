# frozen_string_literal: true

require 'thor'
require 'fileutils'
require 'json'
require 'time'
require_relative 'helpers/maintenance_page_helper'
require_relative 'config_loader'
require_relative 'webhook'
require_relative 'cli/status_printer'

module RailsMaint
  class CLI < Thor
    include MaintenancePageHelper

    desc 'install', 'Generate configuration file and locale file'
    method_option :locale, type: :string, default: 'en', desc: 'Set the language for maintenance page'
    def install
      create_config_file
      create_locale_file(options[:locale])
      puts "RailsMaint has been installed with #{options[:locale]} locale."
      puts 'Tip: In Rails apps, you can also use: rails generate rails_maint:install'
    end

    desc 'enable', 'Enable maintenance mode'
    method_option :start, type: :string, default: nil, desc: 'Scheduled start time (e.g., "2024-01-01 10:00")'
    method_option :end, type: :string, default: nil, desc: 'Scheduled end time (e.g., "2024-01-01 12:00")'
    def enable
      FileUtils.mkdir_p('tmp')

      data = build_schedule_data
      File.write('tmp/maintenance_mode.txt', data)
      puts 'Maintenance mode enabled.'
      puts "  Scheduled start: #{options[:start]}" if options[:start]
      puts "  Scheduled end: #{options[:end]}" if options[:end]

      Instrumentation.instrument('enabled', start_time: options[:start], end_time: options[:end])
      notify_webhook('maintenance.enabled')
    end

    desc 'disable', 'Disable maintenance mode'
    def disable
      delete_file('tmp/maintenance_mode.txt')
      puts 'Maintenance mode disabled.'
      Instrumentation.instrument('disabled')
      notify_webhook('maintenance.disabled')
    end

    desc 'status', 'Show current maintenance mode status'
    def status
      StatusPrinter.new.print
    end

    desc 'uninstall', 'Remove all files created by RailsMaint'
    def uninstall
      delete_file('tmp/maintenance_mode.txt')
      delete_file('config/rails_maint.yml')
      Dir.glob('config/locales/rails_maint.*.yml').each { |f| delete_file(f) }
      delete_file('config/initializers/rails_maint.rb')
      puts 'RailsMaint has been uninstalled and all related files have been removed.'
    end

    private

    def build_schedule_data
      if options[:start] || options[:end]
        data = { 'enabled_at' => Time.now.iso8601 }
        data['start_time'] = Time.parse(options[:start]).iso8601 if options[:start]
        data['end_time'] = Time.parse(options[:end]).iso8601 if options[:end]
        JSON.generate(data)
      else
        Time.now.to_s
      end
    end

    def notify_webhook(event)
      config = ConfigLoader.load
      url = config['webhook_url']
      Webhook.notify(url, event: event) if url
    end

    def create_locale_file(locale = 'en')
      locale_dir = 'config/locales'
      FileUtils.mkdir_p(locale_dir)

      locale_file_path = "#{locale_dir}/rails_maint.#{locale}.yml"
      return if File.exist?(locale_file_path)

      base_path = File.expand_path(__dir__)
      source_locale_file = File.join(base_path, "assets/locales/#{locale}.yml")

      unless File.exist?(source_locale_file)
        puts "Error: Locale '#{locale}' is not supported. Available locales: #{available_locales.join(', ')}"
        return
      end

      FileUtils.cp(source_locale_file, locale_file_path)
    end

    def create_config_file
      config_path = 'config/rails_maint.yml'
      return if File.exist?(config_path)

      FileUtils.mkdir_p('config')
      File.write(config_path, default_config_content)
    end

    def delete_file(path)
      if File.exist?(path)
        File.delete(path)
        puts "#{path} has been removed."
      else
        puts "#{path} does not exist, so it cannot be removed."
      end
    end

    def default_config_content
      <<~YAML
        # RailsMaint Configuration
        # -----------------------

        # Default locale for maintenance page
        locale: #{options[:locale] || 'en'}

        # IP addresses that can access the application during maintenance
        white_listed_ips:
          - 127.0.0.1
          - "::1"
          # Add more IPs below
          # - 192.168.1.1
      YAML
    end
  end
end
