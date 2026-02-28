# frozen_string_literal: true

module RailsMaint
  module PathMatcher
    def self.match?(pattern, request_path)
      if pattern.end_with?('/*')
        prefix = pattern.chomp('/*')
        request_path.start_with?(prefix)
      else
        request_path == pattern
      end
    end

    def self.any_match?(patterns, request_path)
      patterns.any? { |pattern| match?(pattern, request_path) }
    end
  end
end
