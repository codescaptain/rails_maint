# frozen_string_literal: true

module RailsMaint
  module Instrumentation
    def self.instrument(event, payload = {})
      return unless defined?(ActiveSupport::Notifications)

      ActiveSupport::Notifications.instrument("#{event}.rails_maint", payload)
    end
  end
end
