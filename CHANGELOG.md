# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Configuration DSL** — `RailsMaint.configure { |c| c.retry_after = 1800 }` for programmatic configuration
- **Railtie** — Middleware is now auto-registered in Rails apps (no manual `config.middleware.use` needed)
- **Rails Generator** — `rails generate rails_maint:install` creates config, locale, and initializer files
- **Retry-After header** — 503 responses include a `Retry-After` header (default: 3600s, configurable)
- **Route-based maintenance** — `bypass_paths` (always accessible) and `maintenance_paths` (only these paths show maintenance)
- **Custom maintenance page** — Serve a custom HTML file instead of the default template
- **Scheduled maintenance** — `rails_maint enable --start="..." --end="..."` for time-windowed maintenance
- **CLI `status` command** — `rails_maint status` shows current maintenance state and configuration
- **Webhook notifications** — POST JSON to a configured URL on enable/disable events
- **ConfigLoader module** — Shared YAML config loading extracted from middleware and CLI
- **Schedule module** — Parses scheduled maintenance windows with backward-compatible flag file format
- `remaining_time` translation key added to en.yml and tr.yml

### Security
- Fix IP spoofing vulnerability via X-Forwarded-For header
- Fix XSS vulnerability in maintenance page template
- Fix YAML deserialization vulnerability (switched to safe_load)
- Fix path traversal vulnerability in locale handling
- Path traversal protection for custom maintenance page

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
- Installation reduced from 4 steps to 2 steps (`bundle add` + `rails generate`)
- Middleware refactored to use Configuration DSL with YAML precedence
- CLI `uninstall` now also removes the initializer file

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
