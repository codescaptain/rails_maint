# frozen_string_literal: true

require 'yaml'
require 'cgi'

module RailsMaint
  module MaintenancePageHelper
    ALLOWED_LOCALE_PATTERN = /\A[a-z]{2}(-[A-Z]{2})?\z/

    def default_maintenance_page_content(locale = 'en')
      raise ArgumentError, "Invalid locale format: #{locale.inspect}" unless locale.to_s.match?(ALLOWED_LOCALE_PATTERN)

      base_path = File.expand_path('..', __dir__)
      css_content = File.read(File.join(base_path, 'assets/default.css'))
      html_template = File.read(File.join(base_path, 'assets/maintenance.html'))
      translations = load_translations(base_path, locale)

      apply_template(html_template, css_content, locale, translations)
    end

    def available_locales
      base_path = File.expand_path('..', __dir__)
      locale_dir = File.join(base_path, 'assets/locales')
      app_locale_dir = 'config/locales'

      gem_locales = Dir.glob("#{locale_dir}/*.yml").map { |f| File.basename(f, '.yml') }
      app_locales = if Dir.exist?(app_locale_dir)
                      Dir.glob("#{app_locale_dir}/rails_maint.*.yml")
                         .map { |f| File.basename(f, '.yml').split('.').last }
                    else
                      []
                    end

      (gem_locales + app_locales).uniq
    end

    private

    def load_translations(base_path, locale)
      app_locale_file = "config/locales/rails_maint.#{locale}.yml"
      gem_locale_file = File.join(base_path, "assets/locales/#{locale}.yml")
      source = File.exist?(app_locale_file) ? app_locale_file : gem_locale_file

      YAML.safe_load_file(source, permitted_classes: [])[locale]['rails_maint']
    end

    def apply_template(html_template, css_content, locale, translations)
      html_template
        .gsub('<%= css_content %>', css_content)
        .gsub('<%= lang %>', CGI.escapeHTML(locale.to_s))
        .gsub('<%= title %>', CGI.escapeHTML(translations['title'].to_s))
        .gsub('<%= description %>', CGI.escapeHTML(translations['description'].to_s))
        .gsub('<%= estimated_time %>', CGI.escapeHTML(translations['estimated_time'].to_s))
    end
  end
end
