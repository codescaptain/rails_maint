# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'json'

RSpec.describe RailsMaint::Middleware do
  let(:inner_app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:middleware) { described_class.new(inner_app) }
  let(:env) { { 'REMOTE_ADDR' => '192.168.1.100', 'PATH_INFO' => '/' } }

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
  def enable_maintenance_mode(content = nil)
    FileUtils.mkdir_p('tmp')
    File.write('tmp/maintenance_mode.txt', content || Time.now.to_s)
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

        expect(headers['Content-Type']).to eq('text/html')
      end

      it 'includes a Retry-After header' do
        _status, headers, _body = middleware.call(env)

        expect(headers['Retry-After']).to eq('3600')
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
        whitelisted_env = { 'REMOTE_ADDR' => '10.0.0.1', 'PATH_INFO' => '/' }
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
          'HTTP_X_FORWARDED_FOR' => '10.0.0.1',
          'PATH_INFO' => '/'
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
          'HTTP_X_FORWARDED_FOR' => '192.168.1.100',
          'PATH_INFO' => '/'
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

      it 'loads and uses the YAML content' do
        enable_maintenance_mode
        # 10.0.0.1 is whitelisted, but we're using 192.168.1.100
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
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
  # Retry-After header
  # ---------------------------------------------------------------------------
  describe 'Retry-After header' do
    before { enable_maintenance_mode }

    it 'defaults to 3600 seconds' do
      _status, headers, _body = middleware.call(env)

      expect(headers['Retry-After']).to eq('3600')
    end

    context 'when retry_after is configured in YAML' do
      before { write_config('retry_after' => 1800) }

      it 'uses the configured value' do
        _status, headers, _body = middleware.call(env)

        expect(headers['Retry-After']).to eq('1800')
      end
    end

    context 'when a scheduled end_time exists' do
      it 'computes Retry-After from the remaining time' do
        now = Time.now
        end_time = now + 900
        data = {
          'enabled_at' => now.iso8601,
          'start_time' => now.iso8601,
          'end_time' => end_time.iso8601
        }
        enable_maintenance_mode(JSON.generate(data))

        _status, headers, _body = middleware.call(env)

        # Should be approximately 900 seconds (allow 5s tolerance)
        retry_val = headers['Retry-After'].to_i
        expect(retry_val).to be_between(895, 901)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Bypass paths
  # ---------------------------------------------------------------------------
  describe 'bypass_paths' do
    before { enable_maintenance_mode }

    context 'with bypass_paths configured in YAML' do
      before { write_config('bypass_paths' => ['/health', '/up']) }

      it 'passes through for bypassed paths' do
        health_env = { 'REMOTE_ADDR' => '192.168.1.100', 'PATH_INFO' => '/health' }
        status, _headers, _body = middleware.call(health_env)

        expect(status).to eq(200)
      end

      it 'returns 503 for non-bypassed paths' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end
    end

    context 'with wildcard bypass_paths' do
      before { write_config('bypass_paths' => ['/api/*']) }

      it 'passes through for paths matching the wildcard' do
        api_env = { 'REMOTE_ADDR' => '192.168.1.100', 'PATH_INFO' => '/api/status' }
        status, _headers, _body = middleware.call(api_env)

        expect(status).to eq(200)
      end

      it 'returns 503 for non-matching paths' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end
    end

    context 'with bypass_paths configured via DSL' do
      before do
        RailsMaint.configure { |c| c.bypass_paths = ['/up'] }
      end

      it 'passes through for DSL-configured bypass paths' do
        up_env = { 'REMOTE_ADDR' => '192.168.1.100', 'PATH_INFO' => '/up' }
        status, _headers, _body = middleware.call(up_env)

        expect(status).to eq(200)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Maintenance paths (route-based maintenance)
  # ---------------------------------------------------------------------------
  describe 'maintenance_paths' do
    before { enable_maintenance_mode }

    context 'when maintenance_paths is not configured' do
      it 'affects all paths' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end
    end

    context 'with maintenance_paths configured' do
      before { write_config('maintenance_paths' => ['/api/*']) }

      it 'returns 503 for affected paths' do
        api_env = { 'REMOTE_ADDR' => '192.168.1.100', 'PATH_INFO' => '/api/users' }
        status, _headers, _body = middleware.call(api_env)

        expect(status).to eq(503)
      end

      it 'passes through for unaffected paths' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context 'when bypass_paths and maintenance_paths are both configured' do
      before do
        write_config(
          'maintenance_paths' => ['/api/*'],
          'bypass_paths' => ['/api/health']
        )
      end

      it 'bypass_paths takes precedence' do
        health_env = { 'REMOTE_ADDR' => '192.168.1.100', 'PATH_INFO' => '/api/health' }
        status, _headers, _body = middleware.call(health_env)

        expect(status).to eq(200)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Custom maintenance page
  # ---------------------------------------------------------------------------
  describe 'custom maintenance page' do
    before { enable_maintenance_mode }

    context 'when custom_page points to an existing file' do
      before do
        FileUtils.mkdir_p('public')
        File.write('public/maintenance.html', '<html><body>Custom Maintenance</body></html>')
        write_config('custom_page' => 'public/maintenance.html')
      end

      it 'serves the custom page' do
        _status, _headers, body = middleware.call(env)

        expect(body.first).to include('Custom Maintenance')
      end
    end

    context 'when custom_page points to a non-existent file' do
      before do
        write_config('custom_page' => 'public/nonexistent.html')
      end

      it 'falls back to the default maintenance page' do
        _status, _headers, body = middleware.call(env)

        expect(body.first).to include('System Maintenance')
      end
    end

    context 'when custom_page_path is configured via DSL' do
      before do
        FileUtils.mkdir_p('public')
        File.write('public/custom.html', '<html><body>DSL Custom</body></html>')
        RailsMaint.configure { |c| c.custom_page_path = 'public/custom.html' }
      end

      it 'serves the DSL-configured custom page' do
        _status, _headers, body = middleware.call(env)

        expect(body.first).to include('DSL Custom')
      end
    end

    context 'with path traversal attempt' do
      before do
        write_config('custom_page' => '../../../etc/passwd')
      end

      it 'falls back to default page' do
        _status, _headers, body = middleware.call(env)

        expect(body.first).to include('System Maintenance')
        expect(body.first).not_to include('root:')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Scheduled maintenance
  # ---------------------------------------------------------------------------
  describe 'scheduled maintenance' do
    context 'with a future start_time' do
      it 'does not activate maintenance' do
        now = Time.now
        data = {
          'enabled_at' => now.iso8601,
          'start_time' => (now + 3600).iso8601,
          'end_time' => (now + 7200).iso8601
        }
        enable_maintenance_mode(JSON.generate(data))

        status, _headers, _body = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context 'with a past end_time' do
      it 'does not activate maintenance' do
        now = Time.now
        data = {
          'enabled_at' => (now - 7200).iso8601,
          'start_time' => (now - 7200).iso8601,
          'end_time' => (now - 3600).iso8601
        }
        enable_maintenance_mode(JSON.generate(data))

        status, _headers, _body = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context 'within the scheduled window' do
      it 'activates maintenance' do
        now = Time.now
        data = {
          'enabled_at' => (now - 60).iso8601,
          'start_time' => (now - 60).iso8601,
          'end_time' => (now + 3600).iso8601
        }
        enable_maintenance_mode(JSON.generate(data))

        status, _headers, _body = middleware.call(env)

        expect(status).to eq(503)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DSL IP whitelisting
  # ---------------------------------------------------------------------------
  describe 'DSL white_listed_ips' do
    before { enable_maintenance_mode }

    context 'when IPs are configured via DSL' do
      before do
        RailsMaint.configure { |c| c.white_listed_ips = ['192.168.1.100'] }
      end

      it 'passes through for DSL-whitelisted IPs' do
        status, _headers, _body = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context 'when IPs are configured via both YAML and DSL' do
      before do
        write_config('white_listed_ips' => ['10.0.0.1'])
        RailsMaint.configure { |c| c.white_listed_ips = ['192.168.1.100'] }
      end

      it 'merges IPs from both sources' do
        # DSL IP
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(200)

        # YAML IP
        yaml_env = { 'REMOTE_ADDR' => '10.0.0.1', 'PATH_INFO' => '/' }
        status2, _headers2, _body2 = middleware.call(yaml_env)
        expect(status2).to eq(200)
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
