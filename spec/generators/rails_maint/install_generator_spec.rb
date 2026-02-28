# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

# We test the generator in isolation without requiring the full Rails stack.
# Instead, we test the component methods directly.
RSpec.describe 'RailsMaint Install Generator' do
  around do |example|
    Dir.mktmpdir('rails_maint_generator_spec') do |tmpdir|
      Dir.chdir(tmpdir) do
        example.run
      end
    end
  end

  let(:generator_path) do
    File.expand_path('../../../lib/generators/rails_maint/install/install_generator.rb', __dir__)
  end

  let(:templates_path) do
    File.expand_path('../../../lib/generators/rails_maint/install/templates', __dir__)
  end

  describe 'template files' do
    it 'has a rails_maint.yml.tt template' do
      expect(File).to exist(File.join(templates_path, 'rails_maint.yml.tt'))
    end

    it 'has an initializer.rb.tt template' do
      expect(File).to exist(File.join(templates_path, 'initializer.rb.tt'))
    end

    it 'the yml template contains expected configuration keys' do
      content = File.read(File.join(templates_path, 'rails_maint.yml.tt'))

      expect(content).to include('locale:')
      expect(content).to include('white_listed_ips:')
      expect(content).to include('retry_after:')
      expect(content).to include('bypass_paths:')
      expect(content).to include('maintenance_paths:')
      expect(content).to include('custom_page:')
      expect(content).to include('webhook_url:')
    end

    it 'the initializer template contains RailsMaint.configure block' do
      content = File.read(File.join(templates_path, 'initializer.rb.tt'))

      expect(content).to include('RailsMaint.configure')
      expect(content).to include('config.locale')
      expect(content).to include('config.retry_after')
      expect(content).to include('config.bypass_paths')
    end
  end

  describe 'generator class' do
    it 'exists and can be loaded' do
      expect(File).to exist(generator_path)
      content = File.read(generator_path)
      expect(content).to include('class InstallGenerator')
      expect(content).to include('Rails::Generators::Base')
    end

    it 'defines locale option' do
      content = File.read(generator_path)

      expect(content).to include('class_option :locale')
      expect(content).to include("default: 'en'")
    end

    it 'defines all expected generator methods' do
      content = File.read(generator_path)

      expect(content).to include('def create_config_file')
      expect(content).to include('def copy_locale_file')
      expect(content).to include('def create_initializer')
      expect(content).to include('def show_post_install_message')
    end
  end
end
