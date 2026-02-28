# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsMaint::Error do
  it 'is a StandardError' do
    expect(described_class.superclass).to eq(StandardError)
  end
end

RSpec.describe RailsMaint::InvalidConfigurationError do
  it 'inherits from RailsMaint::Error' do
    expect(described_class.superclass).to eq(RailsMaint::Error)
  end
end

RSpec.describe RailsMaint::InvalidLocaleError do
  it 'inherits from RailsMaint::Error' do
    expect(described_class.superclass).to eq(RailsMaint::Error)
  end
end

RSpec.describe RailsMaint::ScheduleError do
  it 'inherits from RailsMaint::Error' do
    expect(described_class.superclass).to eq(RailsMaint::Error)
  end
end

RSpec.describe RailsMaint::WebhookError do
  it 'inherits from RailsMaint::Error' do
    expect(described_class.superclass).to eq(RailsMaint::Error)
  end
end
