# frozen_string_literal: true

require 'rails/generators'

module RailsMaint
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :locale, type: :string, default: 'en',
                            desc: 'Set the language for maintenance page (e.g., en, tr)'

      desc 'Installs RailsMaint configuration, locale, and initializer files'

      def create_config_file
        template 'rails_maint.yml.tt', 'config/rails_maint.yml'
      end

      def copy_locale_file
        locale = options[:locale]
        source = gem_locale_path(locale)

        unless File.exist?(source)
          say "Locale '#{locale}' is not supported. Falling back to 'en'.", :red
          locale = 'en'
          source = gem_locale_path(locale)
        end

        copy_file source, "config/locales/rails_maint.#{locale}.yml"
      end

      def create_initializer
        template 'initializer.rb.tt', 'config/initializers/rails_maint.rb'
      end

      def show_post_install_message
        say ''
        say 'RailsMaint installed successfully!', :green
        say ''
        say 'Usage:'
        say '  rails_maint enable   # Enable maintenance mode'
        say '  rails_maint disable  # Disable maintenance mode'
        say '  rails_maint status   # Show maintenance status'
        say ''
        say 'Configuration: config/rails_maint.yml'
        say 'Initializer:   config/initializers/rails_maint.rb'
        say ''
      end

      private

      def gem_locale_path(locale)
        File.expand_path("../../../../rails_maint/assets/locales/#{locale}.yml", __dir__)
      end
    end
  end
end
