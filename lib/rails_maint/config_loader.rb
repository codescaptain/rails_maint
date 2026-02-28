# frozen_string_literal: true

require 'yaml'

module RailsMaint
  module ConfigLoader
    def self.load(path = nil)
      path ||= RailsMaint.configuration.config_file_path
      if File.exist?(path)
        YAML.safe_load_file(path, permitted_classes: []) || {}
      else
        {}
      end
    end
  end
end
