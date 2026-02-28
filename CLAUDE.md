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

### feature-developer
End-to-end feature development from design to merge-ready code. Workflow:
1. **Explore** — Read existing code to understand patterns, find where the feature fits
2. **Plan** — Identify files to create/modify, define the public API, consider edge cases
3. **Implement** — Write code following project conventions:
   - New modules go in `lib/rails_maint/`, matching the existing naming pattern
   - Configuration options added to `Configuration` class with sensible defaults
   - YAML config keys added to `config_loader.rb` and generator templates
   - Middleware features wired through `effective_config` / `effective_array_config` helpers
   - CLI commands follow Thor DSL with `desc`, `method_option`, and private helpers
   - Extract classes when methods exceed 20 lines or classes exceed 100 lines (RuboCop limits)
4. **Test** — Write specs before or alongside implementation:
   - Mirror lib/ path under spec/ (e.g., `lib/rails_maint/foo.rb` → `spec/rails_maint/foo_spec.rb`)
   - Use `Dir.mktmpdir` + `Dir.chdir` for any file I/O
   - Stub external calls (Net::HTTP, Time.now) — no real network or time dependencies
   - Cover happy path, error path, edge cases, and backward compatibility
5. **Lint** — Run `bundle exec rubocop` and fix all offenses before committing
6. **Verify** — Run `bundle exec rspec` — all tests must pass (0 failures)
7. **Document** — Update CHANGELOG.md (Unreleased section) and README.md if user-facing

Checklist for new features:
- [ ] `frozen_string_literal: true` on all new files
- [ ] Single-quote strings unless interpolation needed
- [ ] Configuration DSL attr + YAML key + generator template updated
- [ ] Middleware uses `effective_config` for new settings (YAML > DSL > default precedence)
- [ ] Security: validate/sanitize all external input (paths, IPs, URLs, user strings)
- [ ] Backward compatible — existing config files and flag files must still work
- [ ] Spec file with full coverage
- [ ] `bundle exec rspec` passes (0 failures)
- [ ] `bundle exec rubocop` passes (0 offenses)
- [ ] CHANGELOG.md updated
- [ ] README.md updated if user-facing

## Common Pitfalls

- **Don't require 'rails'** in lib files loaded outside Rails — use `defined?(Rails::Railtie)` guards
- **Middleware caches `@yaml_config`** per instance — this is intentional for performance but means YAML changes need a new request (instance variable, not class variable)
- **Thor CLI** options hash uses symbol keys (`:locale`, `:start`, `:end`)
- **Generator templates** use `.tt` extension and ERB-style `<%= %>` tags
- **Gemfile.lock** is not committed (gem convention — see `.gitignore`)
