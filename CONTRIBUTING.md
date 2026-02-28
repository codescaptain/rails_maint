# Contributing to RailsMaint

Thank you for your interest in contributing to RailsMaint! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Started

### Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/your-username/rails_maint.git
cd rails_maint

# Install dependencies
bundle install

# Run the test suite
bundle exec rspec

# Run the linter
bundle exec rubocop
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/rails_maint_spec.rb

# Run tests with documentation format
bundle exec rspec --format documentation
```

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/codescaptain/rails_maint/issues) to avoid duplicates
2. Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md)
3. Include your Ruby, Rails, and rails_maint versions
4. Provide steps to reproduce the issue

### Suggesting Enhancements

1. Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md)
2. Explain the use case and expected behavior
3. Consider backward compatibility

### Pull Request Process

1. **Fork** the repository
2. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Write tests** for your changes
4. **Write code** that passes all tests
5. **Run the full suite**:
   ```bash
   bundle exec rspec
   bundle exec rubocop
   ```
6. **Commit** with meaningful messages (see below)
7. **Push** to your fork and open a Pull Request

## Code Style

This project uses [RuboCop](https://rubocop.org/) for code style enforcement.

- Use single quotes for strings (unless interpolation is needed)
- Maximum line length: 120 characters
- Maximum method length: 20 lines
- Add `# frozen_string_literal: true` to all Ruby files
- Follow the [Ruby Style Guide](https://rubystyle.guide/)

Run before submitting:
```bash
bundle exec rubocop
```

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
feat: Add German language support

- Add de.yml locale file
- Update available_locales to include German
- Add tests for German locale
```

Prefixes: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`

## Directory Structure

```
rails_maint/
├── lib/
│   ├── rails_maint.rb              # Root module
│   └── rails_maint/
│       ├── version.rb              # Version constant
│       ├── cli.rb                  # Thor CLI commands
│       ├── middleware.rb           # Rack middleware
│       ├── helpers/
│       │   └── maintenance_page_helper.rb
│       └── assets/
│           ├── locales/            # Built-in locale files
│           ├── maintenance.html    # HTML template
│           └── default.css         # Inline styles
├── spec/                           # RSpec tests
├── exe/                            # CLI executable
└── bin/                            # Development scripts
```

## Adding a New Language

1. Create `lib/rails_maint/assets/locales/XX.yml` (use existing `en.yml` as template)
2. Add tests in `spec/`
3. Update README.md with the new language
4. Update CHANGELOG.md

## Release Process

1. Update version in `lib/rails_maint/version.rb`
2. Update `CHANGELOG.md`
3. Create a git tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
4. Push tag: `git push origin vX.Y.Z`
5. GitHub Actions will handle gem publishing

## Questions?

Feel free to [open an issue](https://github.com/codescaptain/rails_maint/issues) or contact the maintainers.
