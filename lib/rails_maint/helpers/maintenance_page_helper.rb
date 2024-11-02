# lib/rails_maint/helpers/maintenance_page_helper.rb
require 'yaml'

module RailsMaint
  module MaintenancePageHelper
    def default_maintenance_page_content(locale = 'en')
      base_path = File.expand_path('../../', __FILE__)
      css_file = File.join(base_path, 'assets/default.css')
      html_file = File.join(base_path, 'assets/maintenance.html')
      locale_file = File.join(base_path, "assets/locales/#{locale}.yml")

      # CSS ve HTML içeriğini oku
      css_content = File.read(css_file)
      html_template = File.read(html_file)

      app_locale_file = "config/locales/rails_maint.#{locale}.yml"

      puts "APP LOCALE FILE: #{app_locale_file}"
      translations = if File.exist?(app_locale_file)
                       YAML.load_file(app_locale_file)[locale]['rails_maint']
                     else
                       YAML.load_file(locale_file)[locale]['rails_maint']
                     end

      # Placeholder'ları değiştir
      html_content = html_template
                       .gsub('<%= css_content %>', css_content)
                       .gsub('<%= lang %>', locale)
                       .gsub('<%= title %>', translations['title'])
                       .gsub('<%= description %>', translations['description'])
                       .gsub('<%= estimated_time %>', translations['estimated_time'])

      html_content
    end

    def available_locales
      base_path = File.expand_path('../../', __FILE__)
      locale_dir = File.join(base_path, 'assets/locales')
      app_locale_dir = 'config/locales'

      gem_locales = Dir.glob("#{locale_dir}/*.yml").map { |f| File.basename(f, '.yml') }
      app_locales = if Dir.exist?(app_locale_dir)
                      Dir.glob("#{app_locale_dir}/rails_maint.*.yml").map { |f| File.basename(f, '.yml').split('.').last }
                    else
                      []
                    end

      (gem_locales + app_locales).uniq
    end
  end
end