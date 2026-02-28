# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'rails_maint/helpers/maintenance_page_helper'

RSpec.describe RailsMaint::MaintenancePageHelper do
  let(:helper_class) do
    Class.new do
      include RailsMaint::MaintenancePageHelper
    end
  end

  let(:helper) { helper_class.new }

  describe '#default_maintenance_page_content' do
    context 'with English locale' do
      subject(:html) { helper.default_maintenance_page_content('en') }

      it 'returns an HTML string' do
        expect(html).to be_a(String)
        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('</html>')
      end

      it 'contains the English title from translations' do
        expect(html).to include('System Maintenance')
      end

      it 'contains CSS content' do
        expect(html).to include('.maintenance-container')
        expect(html).to include('font-family')
      end

      it 'contains the correct lang attribute' do
        expect(html).to include('lang="en"')
      end

      it 'contains the English description' do
        expect(html).to include('Our system is currently being updated...')
      end

      it 'contains the English estimated time' do
        expect(html).to include('Estimated time: 1 hour')
      end
    end

    context 'with Turkish locale' do
      subject(:html) { helper.default_maintenance_page_content('tr') }

      it 'returns Turkish content' do
        expect(html).to include('Sistem Bakımda')
      end

      it 'contains the correct lang attribute for Turkish' do
        expect(html).to include('lang="tr"')
      end

      it 'contains the Turkish description' do
        expect(html).to include('Sistemimiz şu anda güncelleniyor...')
      end
    end

    context 'with default locale parameter' do
      it 'defaults to English when no locale is provided' do
        html = helper.default_maintenance_page_content
        expect(html).to include('lang="en"')
        expect(html).to include('System Maintenance')
      end
    end

    context 'with valid locale formats' do
      it 'accepts two-letter lowercase locale like en' do
        expect { helper.default_maintenance_page_content('en') }.not_to raise_error
      end

      it 'accepts two-letter lowercase locale like tr' do
        expect { helper.default_maintenance_page_content('tr') }.not_to raise_error
      end

      it 'accepts locale with region code like pt-BR' do
        # pt-BR passes format validation but file may not exist - we test format only
        expect do
          helper.default_maintenance_page_content('pt-BR')
        rescue Errno::ENOENT
          # Expected - file does not exist, but format validation passed
          nil
        end.not_to raise_error
      end
    end

    context 'with invalid locale formats' do
      it 'raises ArgumentError for path traversal attempt' do
        expect do
          helper.default_maintenance_page_content('../../etc/passwd')
        end.to raise_error(ArgumentError, /Invalid locale format/)
      end

      it 'raises ArgumentError for empty string' do
        expect do
          helper.default_maintenance_page_content('')
        end.to raise_error(ArgumentError, /Invalid locale format/)
      end

      it 'raises ArgumentError for numeric locale' do
        expect do
          helper.default_maintenance_page_content(123)
        end.to raise_error(ArgumentError, /Invalid locale format/)
      end

      it 'raises ArgumentError for uppercase-only locale' do
        expect do
          helper.default_maintenance_page_content('EN')
        end.to raise_error(ArgumentError, /Invalid locale format/)
      end

      it 'raises ArgumentError for locale with special characters' do
        expect do
          helper.default_maintenance_page_content('e<n')
        end.to raise_error(ArgumentError, /Invalid locale format/)
      end

      it 'raises ArgumentError for overly long locale string' do
        expect do
          helper.default_maintenance_page_content('english')
        end.to raise_error(ArgumentError, /Invalid locale format/)
      end
    end

    context 'with XSS prevention' do
      it 'HTML-escapes translation values to prevent XSS' do
        malicious_translations = {
          'title' => '<script>alert("xss")</script>',
          'description' => '<img onerror="alert(1)">',
          'estimated_time' => '1 & 2 > 0'
        }

        allow(helper).to receive(:load_translations).and_return(malicious_translations)

        html = helper.default_maintenance_page_content('en')

        expect(html).not_to include('<script>alert("xss")</script>')
        expect(html).to include('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;')
        expect(html).not_to include('<img onerror="alert(1)">')
        expect(html).to include('1 &amp; 2 &gt; 0')
      end
    end
  end

  describe '#available_locales' do
    subject(:locales) { helper.available_locales }

    it 'includes en locale' do
      expect(locales).to include('en')
    end

    it 'includes tr locale' do
      expect(locales).to include('tr')
    end

    it 'returns unique values' do
      expect(locales).to eq(locales.uniq)
    end

    it 'returns an array of strings' do
      expect(locales).to all(be_a(String))
    end

    context 'when app locale directory exists with override files' do
      it 'includes app-level locale overrides' do
        Dir.mktmpdir do |tmpdir|
          app_locale_dir = File.join(tmpdir, 'config', 'locales')
          FileUtils.mkdir_p(app_locale_dir)

          File.write(
            File.join(app_locale_dir, 'rails_maint.fr.yml'),
            YAML.dump('fr' => { 'rails_maint' => { 'title' => 'Maintenance' } })
          )

          Dir.chdir(tmpdir) do
            result = helper.available_locales
            expect(result).to include('fr')
          end
        end
      end

      it 'returns unique values when app locale duplicates gem locale' do
        Dir.mktmpdir do |tmpdir|
          app_locale_dir = File.join(tmpdir, 'config', 'locales')
          FileUtils.mkdir_p(app_locale_dir)

          File.write(
            File.join(app_locale_dir, 'rails_maint.en.yml'),
            YAML.dump('en' => { 'rails_maint' => { 'title' => 'Maintenance' } })
          )

          Dir.chdir(tmpdir) do
            result = helper.available_locales
            expect(result.count('en')).to eq(1)
          end
        end
      end
    end

    context 'when app locale directory does not exist' do
      it 'returns only gem locales' do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            result = helper.available_locales
            expect(result).to include('en', 'tr')
          end
        end
      end
    end
  end

  describe '#load_translations (private)' do
    let(:base_path) do
      source_file = RailsMaint::MaintenancePageHelper.instance_method(
        :default_maintenance_page_content
      ).source_location.first
      File.expand_path('..', File.dirname(source_file))
    end

    context 'when app locale file exists' do
      it 'loads translations from the app locale file' do
        Dir.mktmpdir do |tmpdir|
          app_locale_dir = File.join(tmpdir, 'config', 'locales')
          FileUtils.mkdir_p(app_locale_dir)

          app_translations = {
            'en' => {
              'rails_maint' => {
                'title' => 'App Maintenance',
                'description' => 'App is being updated...',
                'estimated_time' => 'Back in 30 minutes'
              }
            }
          }

          File.write(
            File.join(app_locale_dir, 'rails_maint.en.yml'),
            YAML.dump(app_translations)
          )

          Dir.chdir(tmpdir) do
            result = helper.send(:load_translations, base_path, 'en')
            expect(result['title']).to eq('App Maintenance')
            expect(result['description']).to eq('App is being updated...')
          end
        end
      end
    end

    context 'when app locale file does not exist' do
      it 'falls back to the gem locale file' do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            result = helper.send(:load_translations, base_path, 'en')
            expect(result['title']).to eq('System Maintenance')
          end
        end
      end
    end
  end
end
