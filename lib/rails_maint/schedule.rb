# frozen_string_literal: true

require 'json'
require 'time'

module RailsMaint
  class Schedule
    attr_reader :enabled_at, :start_time, :end_time

    def initialize(enabled_at: nil, start_time: nil, end_time: nil)
      @enabled_at = enabled_at
      @start_time = start_time
      @end_time = end_time
    end

    def self.load(path)
      return new unless File.exist?(path)

      content = File.read(path).strip
      return new unless content.length.positive?

      parse(content)
    end

    def active?(now = Time.now)
      return false if @enabled_at.nil? && @start_time.nil?

      if @start_time
        return false if now < @start_time
        return false if @end_time && now > @end_time
      end

      true
    end

    def seconds_until_end(now = Time.now)
      return nil unless @end_time

      remaining = (@end_time - now).ceil
      remaining.positive? ? remaining : nil
    end

    def self.parse(content)
      data = JSON.parse(content)
      new(
        enabled_at: data['enabled_at'] ? Time.parse(data['enabled_at']) : nil,
        start_time: data['start_time'] ? Time.parse(data['start_time']) : nil,
        end_time: data['end_time'] ? Time.parse(data['end_time']) : nil
      )
    rescue JSON::ParserError
      # Legacy format: plain timestamp string
      new(enabled_at: Time.parse(content))
    rescue ArgumentError
      # Unparseable content — treat as immediate maintenance
      new(enabled_at: Time.now)
    end

    private_class_method :parse
  end
end
