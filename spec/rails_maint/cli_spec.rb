# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'json'

RSpec.describe RailsMaint::CLI do
  subject(:cli) { described_class.new }

  let(:config_file) { 'config/rails_maint.yml' }
  let(:locale_file_en) { 'config/locales/rails_maint.en.yml' }
  let(:locale_file_tr) { 'config/locales/rails_maint.tr.yml' }
  let(:maintenance_file) { 'tmp/maintenance_mode.txt' }

  around do |example|
    Dir.mktmpdir('rails_maint_test') do |tmpdir|
      Dir.chdir(tmpdir) do
        example.run
      end
    end
  end

  # Suppress stdout for all examples unless we explicitly need to capture it
  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  describe '#install' do
    context 'with default locale' do
      it 'creates config/rails_maint.yml' do
        capture_stdout { cli.invoke(:install) }

        expect(File).to exist(config_file)
      end

      it 'writes default configuration content to the config file' do
        capture_stdout { cli.invoke(:install) }

        content = File.read(config_file)
        expect(content).to include('white_listed_ips')
        expect(content).to include('127.0.0.1')
        expect(content).to include('locale:')
      end

      it 'creates config/locales/rails_maint.en.yml' do
        capture_stdout { cli.invoke(:install) }

        expect(File).to exist(locale_file_en)
      end

      it 'copies the English locale content correctly' do
        capture_stdout { cli.invoke(:install) }

        content = YAML.safe_load_file(locale_file_en)
        expect(content.dig('en', 'rails_maint', 'title')).to eq('System Maintenance')
      end

      it 'prints installation confirmation message' do
        output = capture_stdout { cli.invoke(:install) }

        expect(output).to include('RailsMaint has been installed with en locale.')
      end

      it 'prints the Rails generator tip' do
        output = capture_stdout { cli.invoke(:install) }

        expect(output).to include('Tip: In Rails apps, you can also use: rails generate rails_maint:install')
      end
    end

    context 'with --locale=tr option' do
      it 'creates the Turkish locale file' do
        capture_stdout { cli.invoke(:install, [], locale: 'tr') }

        expect(File).to exist(locale_file_tr)
      end

      it 'copies the Turkish locale content correctly' do
        capture_stdout { cli.invoke(:install, [], locale: 'tr') }

        content = YAML.safe_load_file(locale_file_tr)
        expect(content.dig('tr', 'rails_maint', 'title')).to eq('Sistem Bakımda')
      end

      it 'prints installation confirmation with tr locale' do
        output = capture_stdout { cli.invoke(:install, [], locale: 'tr') }

        expect(output).to include('RailsMaint has been installed with tr locale.')
      end
    end

    context 'when config file already exists' do
      before do
        FileUtils.mkdir_p('config')
        File.write(config_file, 'existing content')
      end

      it 'does not overwrite the existing config file' do
        capture_stdout { cli.invoke(:install) }

        expect(File.read(config_file)).to eq('existing content')
      end
    end

    context 'when locale file already exists' do
      before do
        FileUtils.mkdir_p('config/locales')
        File.write(locale_file_en, 'existing locale content')
      end

      it 'does not overwrite the existing locale file' do
        capture_stdout { cli.invoke(:install) }

        expect(File.read(locale_file_en)).to eq('existing locale content')
      end
    end

    context 'with an unsupported locale' do
      it 'prints an error message for the unsupported locale' do
        output = capture_stdout { cli.invoke(:install, [], locale: 'zz') }

        expect(output).to include("Error: Locale 'zz' is not supported.")
      end

      it 'does not create a locale file for the unsupported locale' do
        capture_stdout { cli.invoke(:install, [], locale: 'zz') }

        expect(File).not_to exist('config/locales/rails_maint.zz.yml')
      end
    end
  end

  describe '#enable' do
    it 'creates tmp/maintenance_mode.txt' do
      capture_stdout { cli.invoke(:enable) }

      expect(File).to exist(maintenance_file)
    end

    it 'creates the tmp/ directory if it does not exist' do
      expect(Dir).not_to exist('tmp')

      capture_stdout { cli.invoke(:enable) }

      expect(Dir).to exist('tmp')
    end

    it 'writes a timestamp to the maintenance file' do
      freeze_time = Time.now
      allow(Time).to receive(:now).and_return(freeze_time)

      capture_stdout { cli.invoke(:enable) }

      content = File.read(maintenance_file)
      expect(content).to eq(freeze_time.to_s)
    end

    it 'prints a confirmation message' do
      output = capture_stdout { cli.invoke(:enable) }

      expect(output).to include('Maintenance mode enabled.')
    end

    context 'when tmp/ directory already exists' do
      before { FileUtils.mkdir_p('tmp') }

      it 'does not raise an error' do
        expect { capture_stdout { cli.invoke(:enable) } }.not_to raise_error
      end
    end

    context 'with --start and --end options' do
      it 'writes JSON data with schedule information' do
        capture_stdout do
          cli.invoke(:enable, [], start: '2024-06-01 10:00', end: '2024-06-01 12:00')
        end

        content = File.read(maintenance_file)
        data = JSON.parse(content)

        expect(data).to have_key('enabled_at')
        expect(data).to have_key('start_time')
        expect(data).to have_key('end_time')
      end

      it 'prints schedule information' do
        output = capture_stdout do
          cli.invoke(:enable, [], start: '2024-06-01 10:00', end: '2024-06-01 12:00')
        end

        expect(output).to include('Scheduled start: 2024-06-01 10:00')
        expect(output).to include('Scheduled end: 2024-06-01 12:00')
      end
    end

    context 'with only --end option' do
      it 'writes JSON data with end_time but no start_time' do
        capture_stdout do
          cli.invoke(:enable, [], end: '2024-06-01 12:00')
        end

        content = File.read(maintenance_file)
        data = JSON.parse(content)

        expect(data).to have_key('enabled_at')
        expect(data).not_to have_key('start_time')
        expect(data).to have_key('end_time')
      end
    end
  end

  describe '#disable' do
    context 'when maintenance file exists' do
      before do
        FileUtils.mkdir_p('tmp')
        File.write(maintenance_file, Time.now.to_s)
      end

      it 'removes the maintenance file' do
        capture_stdout { cli.invoke(:disable) }

        expect(File).not_to exist(maintenance_file)
      end

      it 'prints that the file has been removed' do
        output = capture_stdout { cli.invoke(:disable) }

        expect(output).to include("#{maintenance_file} has been removed.")
      end

      it 'prints the disable confirmation message' do
        output = capture_stdout { cli.invoke(:disable) }

        expect(output).to include('Maintenance mode disabled.')
      end
    end

    context 'when maintenance file does not exist' do
      it 'does not raise an error' do
        expect { capture_stdout { cli.invoke(:disable) } }.not_to raise_error
      end

      it 'prints that the file does not exist' do
        output = capture_stdout { cli.invoke(:disable) }

        expect(output).to include("#{maintenance_file} does not exist, so it cannot be removed.")
      end

      it 'still prints the disable confirmation message' do
        output = capture_stdout { cli.invoke(:disable) }

        expect(output).to include('Maintenance mode disabled.')
      end
    end
  end

  describe '#status' do
    context 'when maintenance mode is disabled' do
      it 'shows DISABLED status' do
        output = capture_stdout { cli.invoke(:status) }

        expect(output).to include('Status: DISABLED')
      end
    end

    context 'when maintenance mode is enabled' do
      before do
        FileUtils.mkdir_p('tmp')
        File.write(maintenance_file, Time.now.to_s)
      end

      it 'shows ENABLED status' do
        output = capture_stdout { cli.invoke(:status) }

        expect(output).to include('Status: ENABLED')
      end
    end

    context 'when maintenance mode is enabled with schedule' do
      before do
        FileUtils.mkdir_p('tmp')
        now = Time.now
        data = {
          'enabled_at' => now.iso8601,
          'start_time' => now.iso8601,
          'end_time' => (now + 3600).iso8601
        }
        File.write(maintenance_file, JSON.generate(data))
      end

      it 'shows schedule information' do
        output = capture_stdout { cli.invoke(:status) }

        expect(output).to include('Status: ENABLED')
        expect(output).to include('Start time:')
        expect(output).to include('End time:')
        expect(output).to include('Remaining:')
      end
    end

    context 'with config file present' do
      before do
        FileUtils.mkdir_p('config')
        File.write(config_file, YAML.dump(
                                  'locale' => 'tr',
                                  'white_listed_ips' => ['10.0.0.1'],
                                  'bypass_paths' => ['/health'],
                                  'retry_after' => 1800,
                                  'custom_page' => 'public/maintenance.html',
                                  'webhook_url' => 'https://example.com/hook'
                                ))
      end

      it 'displays configuration details' do
        output = capture_stdout { cli.invoke(:status) }

        expect(output).to include('Locale: tr')
        expect(output).to include('10.0.0.1')
        expect(output).to include('/health')
        expect(output).to include('Retry-After: 1800s')
        expect(output).to include('public/maintenance.html')
        expect(output).to include('https://example.com/hook')
      end
    end

    context 'without config file' do
      it 'shows defaults' do
        output = capture_stdout { cli.invoke(:status) }

        expect(output).to include('Locale: en')
        expect(output).to include('Whitelisted IPs: none')
        expect(output).to include('Bypass paths: none')
        expect(output).to include('Retry-After: 3600s')
      end
    end
  end

  describe '#uninstall' do
    context 'when all files exist' do
      before do
        FileUtils.mkdir_p('tmp')
        FileUtils.mkdir_p('config/locales')
        FileUtils.mkdir_p('config/initializers')
        File.write(maintenance_file, Time.now.to_s)
        File.write(config_file, 'config content')
        File.write(locale_file_en, 'en locale content')
        File.write(locale_file_tr, 'tr locale content')
        File.write('config/initializers/rails_maint.rb', 'initializer content')
      end

      it 'removes the maintenance file' do
        capture_stdout { cli.invoke(:uninstall) }

        expect(File).not_to exist(maintenance_file)
      end

      it 'removes the config file' do
        capture_stdout { cli.invoke(:uninstall) }

        expect(File).not_to exist(config_file)
      end

      it 'removes all locale files matching the pattern' do
        capture_stdout { cli.invoke(:uninstall) }

        expect(File).not_to exist(locale_file_en)
        expect(File).not_to exist(locale_file_tr)
      end

      it 'removes the initializer file' do
        capture_stdout { cli.invoke(:uninstall) }

        expect(File).not_to exist('config/initializers/rails_maint.rb')
      end

      it 'prints removal messages for each file' do
        output = capture_stdout { cli.invoke(:uninstall) }

        expect(output).to include("#{maintenance_file} has been removed.")
        expect(output).to include("#{config_file} has been removed.")
        expect(output).to include("#{locale_file_en} has been removed.")
        expect(output).to include("#{locale_file_tr} has been removed.")
        expect(output).to include('config/initializers/rails_maint.rb has been removed.')
      end

      it 'prints the uninstall confirmation message' do
        output = capture_stdout { cli.invoke(:uninstall) }

        expect(output).to include(
          'RailsMaint has been uninstalled and all related files have been removed.'
        )
      end
    end

    context 'when files have already been removed' do
      it 'does not raise an error' do
        expect { capture_stdout { cli.invoke(:uninstall) } }.not_to raise_error
      end

      it 'prints does-not-exist messages for missing files' do
        output = capture_stdout { cli.invoke(:uninstall) }

        expect(output).to include(
          "#{maintenance_file} does not exist, so it cannot be removed."
        )
        expect(output).to include(
          "#{config_file} does not exist, so it cannot be removed."
        )
      end

      it 'still prints the uninstall confirmation message' do
        output = capture_stdout { cli.invoke(:uninstall) }

        expect(output).to include(
          'RailsMaint has been uninstalled and all related files have been removed.'
        )
      end
    end

    context 'when only some files exist' do
      before do
        FileUtils.mkdir_p('config')
        File.write(config_file, 'config content')
      end

      it 'removes existing files and handles missing ones gracefully' do
        output = capture_stdout { cli.invoke(:uninstall) }

        expect(File).not_to exist(config_file)
        expect(output).to include("#{config_file} has been removed.")
        expect(output).to include(
          "#{maintenance_file} does not exist, so it cannot be removed."
        )
      end
    end
  end
end
