# CLAUDE.md — Project Intelligence for rails_maint

## Project Overview

RailsMaint is a Ruby gem that provides maintenance mode functionality for Rails applications. It includes Rack middleware, a Thor CLI, a Rails generator, Configuration DSL, scheduled maintenance, webhook notifications, and route-based maintenance.

## Tech Stack

- **Language:** Ruby (>= 3.0)
- **Framework:** Rails (>= 6.0) — runtime dependency
- **CLI:** Thor (~> 1.3)
- **Testing:** RSpec (~> 3.12)
- **Linting:** RuboCop (~> 1.75), rubocop-rails (~> 2.29), rubocop-rspec (~> 3.5)
- **CI:** GitHub Actions (Ruby 3.0–3.3 matrix)

## Project Structure

```
lib/
├── rails_maint.rb                  # Entry point — loads all modules
├── rails_maint/
│   ├── version.rb                  # Gem version constant
│   ├── configuration.rb            # Configuration DSL (RailsMaint.configure)
│   ├── config_loader.rb            # Shared YAML config loading
│   ├── middleware.rb               # Rack middleware (503 + maintenance page)
│   ├── railtie.rb                  # Auto-registers middleware in Rails
│   ├── schedule.rb                 # Scheduled maintenance window parsing
│   ├── webhook.rb                  # Webhook notification sender
│   ├── cli.rb                      # Thor CLI (install/enable/disable/status/uninstall)
│   ├── cli/
│   │   └── status_printer.rb       # Extracted status display logic
│   ├── helpers/
│   │   └── maintenance_page_helper.rb  # HTML template rendering + locale handling
│   └── assets/
│       ├── default.css             # Maintenance page CSS
│       ├── maintenance.html        # Maintenance page HTML template
│       └── locales/
│           ├── en.yml              # English translations
│           └── tr.yml              # Turkish translations
├── generators/
│   └── rails_maint/install/
│       ├── install_generator.rb    # Rails generator
│       └── templates/
│           ├── rails_maint.yml.tt  # Config template
│           └── initializer.rb.tt   # Initializer template
spec/
├── spec_helper.rb
├── rails_maint_spec.rb
├── rails_maint/
│   ├── middleware_spec.rb
│   ├── cli_spec.rb
│   ├── configuration_spec.rb
│   ├── schedule_spec.rb
│   ├── webhook_spec.rb
│   └── maintenance_page_helper_spec.rb
└── generators/rails_maint/
    └── install_generator_spec.rb
```

## Key Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Run specific test file
bundle exec rspec spec/rails_maint/middleware_spec.rb

# Auto-correct RuboCop offenses
bundle exec rubocop -A
```

## Coding Conventions

- **String literals:** Single quotes unless interpolation is needed (`'hello'` not `"hello"`)
- **Frozen string literal:** Required in all lib/ files, excluded for spec/ and exe/
- **Max line length:** 120 characters
- **Max method length:** 20 lines
- **Max ABC size:** 30
- **Block length:** Unlimited in spec/ files and gemspec
- **No documentation cop** — `Style/Documentation` is disabled
- **RuboCop target:** Ruby 3.0

## Architecture Decisions

### Configuration Precedence
YAML config (`config/rails_maint.yml`) > DSL config (`RailsMaint.configure`) > Defaults

### IP Whitelisting
Uses `REMOTE_ADDR` only — never `X-Forwarded-For` (prevents IP spoofing).

### Maintenance File Format
- **Legacy:** Plain timestamp string (`"2024-01-01 10:00:00 +0000"`)
- **Scheduled:** JSON with `enabled_at`, `start_time`, `end_time` keys
- Schedule.load handles both formats for backward compatibility.

### Security
- `YAML.safe_load_file` for all YAML parsing (no arbitrary object deserialization)
- `CGI.escapeHTML` for all template interpolation (XSS prevention)
- Locale validation via strict regex `\A[a-z]{2}(-[A-Z]{2})?\z`
- `File.expand_path` check for custom page paths (path traversal prevention)

### Testing Pattern
- All file-touching specs run inside `Dir.mktmpdir` + `Dir.chdir` blocks
- `RailsMaint.reset_configuration!` runs after each test (in spec_helper.rb)
- No external HTTP calls — webhook specs stub `Net::HTTP`

## Agents / Swarm Roles

### architect
Responsible for planning features, reviewing PRs, and ensuring architectural consistency. Focus areas:
- Middleware pipeline design
- Configuration precedence logic
- Backward compatibility of flag file format
- Security review (IP handling, path traversal, XSS)

### developer
Implements features and bug fixes. Must:
- Run `bundle exec rspec` before committing (147+ tests must pass)
- Run `bundle exec rubocop` before committing (0 offenses)
- Follow single-quote string convention
- Add `frozen_string_literal: true` to all new lib/ files
- Write specs for all new functionality
- Use `Dir.mktmpdir` isolation pattern in file-touching specs

### reviewer
Reviews code changes for:
- Security vulnerabilities (OWASP top 10, especially XSS, path traversal, command injection)
- RuboCop compliance
- Test coverage for new code paths
- Backward compatibility (especially Schedule flag file format)
- No hardcoded paths — use Configuration accessors

### tester
Runs and writes tests. Conventions:
- Spec files mirror lib/ structure under spec/
- Use `let` for shared values, `before`/`around` for setup
- Use `capture_stdout` helper for CLI output assertions
- Test edge cases: missing files, empty config, invalid input
- Reset configuration after each test (handled by spec_helper)

## Common Pitfalls

- **Don't require 'rails'** in lib files loaded outside Rails — use `defined?(Rails::Railtie)` guards
- **Middleware caches `@yaml_config`** per instance — this is intentional for performance but means YAML changes need a new request (instance variable, not class variable)
- **Thor CLI** options hash uses symbol keys (`:locale`, `:start`, `:end`)
- **Generator templates** use `.tt` extension and ERB-style `<%= %>` tags
- **Gemfile.lock** is not committed (gem convention — see `.gitignore`)
