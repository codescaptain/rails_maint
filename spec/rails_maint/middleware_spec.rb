# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'yaml'

RSpec.describe RailsMaint::Middleware do
  let(:inner_app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:middleware) { described_class.new(inner_app) }
  let(:env) { { 'REMOTE_ADDR' => '192.168.1.100' } }

  # Path to the gem's assets directory so we can copy it into the temp dir
  let(:gem_assets_path) do
    File.expand_path('../../lib/rails_maint/assets', __dir__)
  end

  # Run every example inside an isolated temp directory so file operations
  # (tmp/maintenance_mode.txt, config/rails_maint.yml) never touch the real project.
  around do |example|
    Dir.mktmpdir('rails_maint_spec') do |tmpdir|
      # Copy the gem assets into the temp tree so MaintenancePageHelper can
      # resolve its templates via File.expand_path relative to its own __dir__.
      Dir.chdir(tmpdir) do
        example.run
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helper: create the maintenance flag file
  # ---------------------------------------------------------------------------
  def enable_maintenance_mode
    FileUtils.mkdir_p('tmp')
    File.write('tmp/maintenance_mode.txt', '')
  end

  # ---------------------------------------------------------------------------
  # Helper: write a config/rails_maint.yml with the given hash
  # ---------------------------------------------------------------------------
  def write_config(hash)
    FileUtils.mkdir_p('config')
    File.write('config/rails_maint.yml', YAML.dump(hash))
  end

  # ---------------------------------------------------------------------------
  # 1. Passes through when maintenance mode is disabled
  # ---------------------------------------------------------------------------
  describe '#call' do
    context 'when maintenance mode is disabled' do
      it 'delegates to the inner app and returns its response' do
        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers).to eq({ 'Content-Type' => 'text/plain' })
        expect(body).to eq(['OK'])
      end
    end

    # -------------------------------------------------------------------------
    # 2 & 3 & 9. Returns 503 with correct Content-Type and HTML body
    # -------------------------------------------------------------------------
    context 'when maintenance mode is enabled and the IP is not whitelisted' do
      before { enable_maintenance_mode }

      it 'returns a 503 status code' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end

      it 'returns a Content-Type of text/html' do
        _status, headers, _body = middleware.call(env)

        expect(headers).to eq({ 'Content-Type' => 'text/html' })
      end

      it 'returns an HTML body in the response' do
        _status, _headers, body = middleware.call(env)

        expect(body.first).to include('<!DOCTYPE html>')
        expect(body.first).to include('<html')
      end
    end

    # -------------------------------------------------------------------------
    # 4. Passes through when the client IP is whitelisted
    # -------------------------------------------------------------------------
    context 'when maintenance mode is enabled but the IP is whitelisted' do
      before do
        enable_maintenance_mode
        write_config('white_listed_ips' => ['192.168.1.100'])
      end

      it 'delegates to the inner app and returns 200' do
        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['OK'])
      end
    end

    context 'when only some IPs are whitelisted' do
      before do
        enable_maintenance_mode
        write_config('white_listed_ips' => ['10.0.0.1', '10.0.0.2'])
      end

      it 'returns 503 for a non-whitelisted IP' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end

      it 'passes through for a whitelisted IP' do
        whitelisted_env = { 'REMOTE_ADDR' => '10.0.0.1' }
        status, _headers, _body = middleware.call(whitelisted_env)

        expect(status).to eq(200)
      end
    end

    # -------------------------------------------------------------------------
    # 5. Uses REMOTE_ADDR for IP checking (not X-Forwarded-For)
    # -------------------------------------------------------------------------
    context 'when X-Forwarded-For contains a whitelisted IP but REMOTE_ADDR does not' do
      before do
        enable_maintenance_mode
        write_config('white_listed_ips' => ['10.0.0.1'])
      end

      it 'does not use X-Forwarded-For and returns 503' do
        spoofed_env = {
          'REMOTE_ADDR' => '192.168.1.100',
          'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
        }
        status, _headers, _body = middleware.call(spoofed_env)

        expect(status).to eq(503)
      end
    end

    context 'when REMOTE_ADDR is whitelisted regardless of X-Forwarded-For' do
      before do
        enable_maintenance_mode
        write_config('white_listed_ips' => ['10.0.0.1'])
      end

      it 'passes through based on REMOTE_ADDR' do
        correct_env = {
          'REMOTE_ADDR' => '10.0.0.1',
          'HTTP_X_FORWARDED_FOR' => '192.168.1.100'
        }
        status, _headers, _body = middleware.call(correct_env)

        expect(status).to eq(200)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # 6. Returns empty config ({}) when config file is missing
  # ---------------------------------------------------------------------------
  describe '#load_config (via maintenance behavior)' do
    context 'when config/rails_maint.yml does not exist' do
      before { enable_maintenance_mode }

      it 'treats white_listed_ips as empty and blocks all IPs' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end

      it 'returns an empty hash from load_config' do
        result = middleware.send(:load_config)

        expect(result).to eq({})
      end
    end

    # -------------------------------------------------------------------------
    # 7. Loads config from YAML when the file exists
    # -------------------------------------------------------------------------
    context 'when config/rails_maint.yml exists' do
      let(:config_data) do
        {
          'white_listed_ips' => ['10.0.0.1'],
          'locale' => 'tr'
        }
      end

      before { write_config(config_data) }

      it 'loads and returns the YAML content as a hash' do
        result = middleware.send(:load_config)

        expect(result).to eq(config_data)
      end

      it 'parses white_listed_ips correctly' do
        result = middleware.send(:load_config)

        expect(result['white_listed_ips']).to eq(['10.0.0.1'])
      end

      it 'parses locale correctly' do
        result = middleware.send(:load_config)

        expect(result['locale']).to eq('tr')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # 8. Falls back to 'en' locale when not specified in config
  # ---------------------------------------------------------------------------
  describe '#maintenance_page (locale handling)' do
    context 'when no locale is specified in the config' do
      it 'falls back to the en locale' do
        page = middleware.send(:maintenance_page)

        expect(page).to include('lang="en"')
        expect(page).to include('System Maintenance')
      end
    end

    context 'when locale is explicitly set to tr' do
      before { write_config('locale' => 'tr') }

      it 'renders the page in the specified locale' do
        page = middleware.send(:maintenance_page)

        expect(page).to include('lang="tr"')
        expect(page).to include('Sistem Bakımda')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Edge cases
  # ---------------------------------------------------------------------------
  describe 'edge cases' do
    context 'when maintenance file exists but config has no white_listed_ips key' do
      before do
        enable_maintenance_mode
        write_config('locale' => 'en')
      end

      it 'treats white_listed_ips as empty and returns 503' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end
    end

    context 'when white_listed_ips is an empty array' do
      before do
        enable_maintenance_mode
        write_config('white_listed_ips' => [])
      end

      it 'returns 503 for any IP' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end
    end

    context 'when maintenance mode is disabled and config exists' do
      before { write_config('white_listed_ips' => ['192.168.1.100']) }

      it 'still passes through to the inner app' do
        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['OK'])
      end
    end
  end
end
