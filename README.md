# RailsMaint

[![Gem Version](https://badge.fury.io/rb/rails_maint.svg)](https://badge.fury.io/rb/rails_maint)
[![Build Status](https://github.com/codescaptain/rails_maint/workflows/CI/badge.svg)](https://github.com/codescaptain/rails_maint/actions)
[![codecov](https://codecov.io/gh/codescaptain/rails_maint/branch/main/graph/badge.svg)](https://codecov.io/gh/codescaptain/rails_maint)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<img src="https://github.com/user-attachments/assets/4daa45fe-833b-48c5-9f69-457424769804" width="500" height="500" alt="rails_maint">


RailsMaint is a simple and customizable maintenance mode gem for Rails applications. It allows you to display a sleek maintenance page to your users during maintenance work.

## Features

- Easy setup — just 2 commands to install
- Automatic middleware registration via Railtie
- Configuration DSL and YAML config support
- Retry-After HTTP header for SEO-friendly 503 responses
- Route-based maintenance with bypass paths
- Scheduled maintenance windows with auto-deactivation
- Custom maintenance page support
- Multi-language support (English and Turkish)
- IP whitelist support
- CLI commands (install, enable, disable, status, uninstall)
- Webhook notifications on enable/disable events
- Rails Generator for quick setup

## Installation

### Rails Apps (Recommended)

```bash
bundle add rails_maint
rails generate rails_maint:install
```

That's it! The Railtie automatically registers the middleware. The generator creates:
- `config/rails_maint.yml` — Configuration file
- `config/locales/rails_maint.en.yml` — Language file
- `config/initializers/rails_maint.rb` — Initializer with DSL configuration

### Manual Setup

1. Add to your Gemfile:

```ruby
gem 'rails_maint'
```

2. Run:

```bash
bundle install
rails_maint install
```

3. If you need manual middleware registration (the Railtie handles this automatically):

```ruby
# config/application.rb
config.middleware.use RailsMaint::Middleware
```

## Usage

### Managing Maintenance Mode

```bash
# Enable maintenance mode
rails_maint enable

# Enable with scheduled window
rails_maint enable --start="2024-06-01 10:00" --end="2024-06-01 12:00"

# Disable maintenance mode
rails_maint disable

# Check current status
rails_maint status

# Remove all RailsMaint files
rails_maint uninstall
```

### Status Command

```bash
$ rails_maint status
Status: ENABLED
  Enabled at: 2024-06-01 10:00:00 +0000
  Start time: 2024-06-01 10:00:00 +0000
  End time:   2024-06-01 12:00:00 +0000
  Remaining:  3542s

Locale: en
Whitelisted IPs: 127.0.0.1, ::1
Bypass paths: /health, /up
Retry-After: 3600s
Custom page: none
Webhook URL: none
```

## Configuration

### YAML Configuration

Customize your settings in `config/rails_maint.yml`:

```yaml
# Default language setting
locale: en

# IP addresses allowed to access during maintenance
white_listed_ips:
  - 127.0.0.1
  - "::1"

# Retry-After header value in seconds (default: 3600)
retry_after: 3600

# Paths that bypass maintenance mode (always accessible)
bypass_paths:
  - /health
  - /up
  - /api/status

# Only apply maintenance to specific paths (empty = all paths)
# maintenance_paths:
#   - /api/*

# Custom maintenance page (relative to app root)
# custom_page: public/maintenance.html

# Webhook URL for maintenance notifications
# webhook_url: https://hooks.slack.com/services/...
```

### DSL Configuration

Configure programmatically in `config/initializers/rails_maint.rb`:

```ruby
RailsMaint.configure do |config|
  config.locale = 'en'
  config.white_listed_ips = ['127.0.0.1', '::1']
  config.retry_after = 3600
  config.bypass_paths = ['/health', '/up']
  config.maintenance_paths = []
  config.custom_page_path = 'public/maintenance.html'
  config.webhook_url = 'https://hooks.slack.com/services/...'
end
```

**Precedence:** YAML config > DSL config > defaults

## Route-Based Maintenance

### Bypass Paths

Keep certain endpoints accessible during maintenance:

```yaml
bypass_paths:
  - /health
  - /up
  - /api/status
```

### Maintenance Paths

Only show maintenance for specific paths (all others pass through):

```yaml
maintenance_paths:
  - /api/*
```

Wildcard matching is supported with `/*` suffix for prefix matching. When both are configured, `bypass_paths` takes precedence.

## Scheduled Maintenance

Schedule a maintenance window that auto-deactivates:

```bash
rails_maint enable --start="2024-06-01 10:00" --end="2024-06-01 12:00"
```

- Before `start_time`: requests pass through normally
- Between `start_time` and `end_time`: maintenance page is shown
- After `end_time`: requests pass through again
- The `Retry-After` header is automatically computed from the remaining time

## Custom Maintenance Page

Serve your own HTML file instead of the default template:

```yaml
custom_page: public/maintenance.html
```

The file path is validated against path traversal attacks. If the file doesn't exist, the default template is used as a fallback.

## Webhook Notifications

Get notified when maintenance mode changes:

```yaml
webhook_url: https://hooks.slack.com/services/T00/B00/xxx
```

The gem sends a POST request with a JSON payload:

```json
{
  "event": "maintenance.enabled",
  "timestamp": "2024-06-01T10:00:00+00:00",
  "gem": "rails_maint",
  "version": "0.1.1"
}
```

Events: `maintenance.enabled`, `maintenance.disabled`

## Language Support

Language files are stored in the `config/locales` directory. You can customize existing translations or add new languages:

```yaml
# config/locales/rails_maint.en.yml
en:
  rails_maint:
    title: "System Maintenance"
    description: "Our system is currently being updated..."
    estimated_time: "Estimated time: 1 hour"
    remaining_time: "Estimated remaining time: %{time}"
```

## How IP Whitelist Works

- When maintenance mode is active, IPs in the whitelist can access the site normally
- All other IPs will see the maintenance page
- The gem uses `REMOTE_ADDR` for IP checking (not `X-Forwarded-For`, to prevent spoofing)
- IPs can be configured via both YAML and DSL (merged from both sources)

## Requirements

- Rails 6.0 or higher
- Ruby 3.0 or higher

## Development

1. Clone the repository
2. Install dependencies: `bundle install`
3. Run tests: `bundle exec rspec`
4. Run linter: `bundle exec rubocop`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing_feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing_feature`)
5. Create a Pull Request

## Security

- Uses `REMOTE_ADDR` for IP validation (prevents spoofing via `X-Forwarded-For`)
- HTML-escapes all translation values to prevent XSS
- Uses `YAML.safe_load_file` for safe deserialization
- Validates locale format with strict regex pattern
- Path traversal protection for custom maintenance pages and locale files

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Contact & Support

- GitHub Issues: [rails_maint/issues](https://github.com/codescaptain/rails_maint/issues)
- Email: [ahmet-57-@hotmail.com](mailto:ahmet-57-@hotmail.com)

## Credits

Developed and maintained by [CodesCaptain](https://github.com/codescaptain)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.
