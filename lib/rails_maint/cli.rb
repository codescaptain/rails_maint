# lib/rails_maint/cli.rb
require 'thor'
require 'fileutils'
require_relative 'helpers/maintenance_page_helper'

module RailsMaint
  class CLI < Thor
    include MaintenancePageHelper

    desc "install", "Generate configuration file and locale file"
    method_option :locale, type: :string, default: 'en', desc: "Set the language for maintenance page"
    def install
      create_config_file
      create_locale_file(options[:locale])
      puts "RailsMaint has been installed with #{options[:locale]} locale."
    end

    desc "enable", "Enable maintenance mode"
    def enable
      File.write('tmp/maintenance_mode.txt', Time.now.to_s)
      puts "Maintenance mode enabled."
    end

    desc "disable", "Disable maintenance mode"
    def disable
      delete_file('tmp/maintenance_mode.txt')
      puts "Maintenance mode disabled"
    end

    desc "uninstall", "Remove all files created by RailsMaint"
    def uninstall
      delete_file('tmp/maintenance_mode.txt')
      delete_file('config/rails_maint.yml')
      delete_file('config/locales/rails_maint.en.yml')
      delete_file('config/locales/rails_maint.tr.yml')
      delete_file('config/locales/rails_maint.ar.yml')
      delete_file('config/locales/rails_maint.es.yml')
      delete_file('config/locales/rails_maint.ru.yml')
      delete_file('config/locales/rails_maint.fr.yml')
      puts "RailsMaint has been uninstalled and all related files have been removed."
    end

    private

    def create_maintenance_page(locale = 'en')
      maintenance_page_path = "public/maintenance.html"
      unless File.exist?(maintenance_page_path)
        File.write(maintenance_page_path, default_maintenance_page_content(locale))
      end
    end

    def create_locale_file(locale = 'en')
      locale_dir = "config/locales"
      FileUtils.mkdir_p(locale_dir) unless Dir.exist?(locale_dir)

      locale_file_path = "#{locale_dir}/rails_maint.#{locale}.yml"
      unless File.exist?(locale_file_path)
        base_path = File.expand_path('../', __FILE__)
        source_locale_file = File.join(base_path, "assets/locales/#{locale}.yml")
        FileUtils.cp(source_locale_file, locale_file_path)
      end
    end

    def create_config_file
      config_path = "config/rails_maint.yml"
      unless File.exist?(config_path)
        File.write(config_path, default_config_content)
      end
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
