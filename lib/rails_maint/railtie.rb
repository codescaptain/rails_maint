# frozen_string_literal: true

module RailsMaint
  class Railtie < Rails::Railtie
    initializer 'rails_maint.logger' do
      RailsMaint.logger = Rails.logger
    end

    initializer 'rails_maint.middleware' do |app|
      app.middleware.use RailsMaint::Middleware
    end
  end
end
