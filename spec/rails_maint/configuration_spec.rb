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

  describe '#validate!' do
    subject(:config) { described_class.new }

    context 'with valid defaults' do
      it 'does not raise' do
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'with invalid locale' do
      it 'raises InvalidLocaleError for path traversal attempt' do
        config.locale = '../../etc'

        expect { config.validate! }.to raise_error(RailsMaint::InvalidLocaleError, /Invalid locale format/)
      end

      it 'raises InvalidLocaleError for uppercase locale' do
        config.locale = 'EN'

        expect { config.validate! }.to raise_error(RailsMaint::InvalidLocaleError)
      end
    end

    context 'with valid locale' do
      it 'accepts two-letter locale' do
        config.locale = 'tr'

        expect { config.validate! }.not_to raise_error
      end

      it 'accepts locale with region' do
        config.locale = 'pt-BR'

        expect { config.validate! }.not_to raise_error
      end

      it 'accepts nil locale' do
        config.locale = nil

        expect { config.validate! }.not_to raise_error
      end
    end

    context 'with invalid retry_after' do
      it 'raises InvalidConfigurationError for zero' do
        config.retry_after = 0

        expect { config.validate! }.to raise_error(RailsMaint::InvalidConfigurationError, /retry_after/)
      end

      it 'raises InvalidConfigurationError for negative' do
        config.retry_after = -100

        expect { config.validate! }.to raise_error(RailsMaint::InvalidConfigurationError)
      end

      it 'raises InvalidConfigurationError for string' do
        config.retry_after = 'abc'

        expect { config.validate! }.to raise_error(RailsMaint::InvalidConfigurationError)
      end
    end

    context 'with invalid webhook_url' do
      it 'raises InvalidConfigurationError for non-HTTP URL' do
        config.webhook_url = 'ftp://example.com'

        expect { config.validate! }.to raise_error(RailsMaint::InvalidConfigurationError, /webhook_url/)
      end

      it 'raises InvalidConfigurationError for malformed URL' do
        config.webhook_url = 'not a url at all %%'

        expect { config.validate! }.to raise_error(RailsMaint::InvalidConfigurationError)
      end
    end

    context 'with valid webhook_url' do
      it 'accepts https URL' do
        config.webhook_url = 'https://hooks.slack.com/services/T00/B00/xxx'

        expect { config.validate! }.not_to raise_error
      end

      it 'accepts http URL' do
        config.webhook_url = 'http://localhost:3000/hook'

        expect { config.validate! }.not_to raise_error
      end

      it 'accepts nil' do
        config.webhook_url = nil

        expect { config.validate! }.not_to raise_error
      end
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

    it 'validates configuration after yielding' do
      expect do
        RailsMaint.configure { |c| c.retry_after = -1 }
      end.to raise_error(RailsMaint::InvalidConfigurationError)
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

  describe '.logger' do
    it 'returns a Logger by default' do
      expect(RailsMaint.logger).to be_a(Logger)
    end

    it 'can be overridden' do
      custom_logger = Logger.new(StringIO.new)
      RailsMaint.logger = custom_logger

      expect(RailsMaint.logger).to be(custom_logger)
    ensure
      RailsMaint.logger = nil
    end
  end
end
