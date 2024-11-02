lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rails_maint/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_maint"
  spec.version       = RailsMaint::VERSION
  spec.authors       = ["codescaptain"]
  spec.email         = ["ahmet-57-@hotmail.com"]

  spec.summary       = "A maintenance mode helper for Rails applications"
  spec.description   = "RailsMaint is a gem that helps you enable maintenance mode for your Rails application with customizable options and IP whitelisting."
  spec.homepage      = "https://github.com/codescaptain/rails_maint"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.6.0"

  # Metadata
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  # Include files
  spec.files = Dir[
    "lib/**/*",
    "exe/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.bindir        = "exe"
  spec.executables   = ["rails_maint"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_runtime_dependency "thor", "~> 1.3"
  spec.add_runtime_dependency "rails", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rails", "~> 2.22"
  spec.add_development_dependency "rubocop-rspec", "~> 2.25"
end