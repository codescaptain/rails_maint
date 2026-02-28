# frozen_string_literal: true

module RailsMaint
  class Error < StandardError; end

  class InvalidConfigurationError < Error; end
  class InvalidLocaleError < Error; end
  class ScheduleError < Error; end
  class WebhookError < Error; end
end
