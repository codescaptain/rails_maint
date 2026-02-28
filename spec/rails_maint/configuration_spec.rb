# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsMaint::Configuration do
  describe 'defaults' do
    subject(:config) { described_class.new }

    it 'has locale defaulting to en' do
      expect(config.locale).to eq('en')
    end

    it 'has empty white_listed_ips' do
      expect(config.white_listed_ips).to eq([])
    end

    it 'has default maintenance_file_path' do
      expect(config.maintenance_file_path).to eq('tmp/maintenance_mode.txt')
    end

    it 'has nil custom_page_path' do
      expect(config.custom_page_path).to be_nil
    end

    it 'has default config_file_path' do
      expect(config.config_file_path).to eq('config/rails_maint.yml')
    end

    it 'has default retry_after of 3600' do
      expect(config.retry_after).to eq(3600)
    end

    it 'has empty bypass_paths' do
      expect(config.bypass_paths).to eq([])
    end

    it 'has empty maintenance_paths' do
      expect(config.maintenance_paths).to eq([])
    end

    it 'has nil webhook_url' do
      expect(config.webhook_url).to be_nil
    end
  end
end

RSpec.describe RailsMaint do
  describe '.configure' do
    it 'yields the configuration object' do
      RailsMaint.configure do |config|
        config.locale = 'tr'
        config.retry_after = 7200
      end

      expect(RailsMaint.configuration.locale).to eq('tr')
      expect(RailsMaint.configuration.retry_after).to eq(7200)
    end
  end

  describe '.configuration' do
    it 'returns the same Configuration instance on repeated calls' do
      expect(RailsMaint.configuration).to be(RailsMaint.configuration)
    end
  end

  describe '.reset_configuration!' do
    it 'resets configuration to defaults' do
      RailsMaint.configure { |c| c.locale = 'tr' }
      RailsMaint.reset_configuration!

      expect(RailsMaint.configuration.locale).to eq('en')
    end

    it 'returns a new Configuration instance' do
      old = RailsMaint.configuration
      RailsMaint.reset_configuration!

      expect(RailsMaint.configuration).not_to be(old)
    end
  end
end
