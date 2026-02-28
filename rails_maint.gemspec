# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_maint/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails_maint'
  spec.version       = RailsMaint::VERSION
  spec.authors       = ['codescaptain']
  spec.email         = ['ahmet-57-@hotmail.com']

  spec.summary       = 'A maintenance mode helper for Rails applications'
  spec.description   = 'RailsMaint is a gem that helps you enable maintenance mode for your ' \
                       'Rails application with customizable options and IP whitelisting.'
  spec.homepage      = 'https://github.com/codescaptain/rails_maint'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0.0'

  # Metadata
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Include files
  spec.files = Dir[
    'lib/**/*',
    'exe/*',
    'LICENSE.txt',
    'README.md',
    'CHANGELOG.md'
  ]

  spec.bindir        = 'exe'
  spec.executables   = ['rails_maint']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'rails', '>= 6.0'
  spec.add_dependency 'thor', '~> 1.3'
end
