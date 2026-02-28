# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- Fix IP spoofing vulnerability via X-Forwarded-For header
- Fix XSS vulnerability in maintenance page template
- Fix YAML deserialization vulnerability (switched to safe_load)
- Fix path traversal vulnerability in locale handling

### Fixed
- Remove debug puts statement from production code path
- Add missing require statements in middleware
- Fix uninstall command to dynamically find locale files
- Add locale validation for install command
- Ensure tmp/ directory exists before writing maintenance file

### Changed
- Minimum Ruby version updated to 3.0+
- Migrated CI from Travis CI to GitHub Actions
- Improved error handling throughout

### Removed
- Remove unused create_maintenance_page method
- Remove obsolete .travis.yml

## [0.1.1] - 2024-03-28

### Added
- Multi-language support (English, Turkish)
- IP whitelist support with proxy header detection
- CLI commands (install, enable, disable, uninstall)
- Rack middleware integration
- Customizable maintenance page with modern design

## [0.1.0] - 2024-03-20

### Added
- Initial release
- Basic maintenance mode functionality
- Simple CLI interface
