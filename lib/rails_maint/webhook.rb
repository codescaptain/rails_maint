# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'time'

module RailsMaint
  module Webhook
    TIMEOUT = 10

    def self.notify(url, event:, timestamp: Time.now)
      return if url.nil? || url.empty?

      uri = URI.parse(url)
      payload = {
        event: event,
        timestamp: timestamp.iso8601,
        gem: 'rails_maint',
        version: RailsMaint::VERSION
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(payload)

      http.request(request)
    rescue StandardError => e
      RailsMaint.logger.warn("[rails_maint] Webhook notification failed: #{e.message}")
    end
  end
end
