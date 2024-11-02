## Development Process

1. Open an Issue
2. Fork the Repository
3. Create a Branch
4. Write Tests
5. Write Code
6. Open Pull Request

## Development Environment

```
# Clone the repository
git clone https://github.com/your-username/rails_maint.git

# Install dependencies
bundle install

# Run tests
bundle exec rspec
```

## Code Style

This project uses Rubocop. Before submitting your code:

```
bundle exec rubocop
```

## Pull Request Process

1. Create a New Branch (feature or fix)
2. Write and Test Your Code
3. Run Rubocop Checks
4. Write Meaningful Commit Messages
5. Open PR and Describe Changes

## Commit Messages

A good commit message looks like:

```
feat: Add Turkish language support

- Add tr.yml locale file
- Update middleware to handle Turkish locale
- Add documentation for Turkish support
```

## Tests

Always write tests for new features:

```
RSpec.describe RailsMaint::Middleware do
describe "#call" do
context "when maintenance mode is enabled" do
it "returns maintenance page for non-whitelisted IPs" do
# Your test code here
end
end
end
end
```

## Documentation

- Update README.md if needed
- Add comments to complex code
- Update CHANGELOG.md
- Add YARDoc documentation for public methods

## Directory Structure

```
rails_maint/
├── lib/
│   ├── rails_maint.rb
│   └── rails_maint/
│       ├── version.rb
│       ├── cli.rb
│       ├── middleware.rb
│       ├── helpers/
│       │   └── maintenance_page_helper.rb
│       └── assets/
│           ├── locales/
│           │   ├── en.yml
│           │   └── tr.yml
│           │   └── ru.yml
│           │   └── es.yml
│           │   └── ar.yml
│           │   └── fr.yml
│           ├── maintenance.html
│           └── default.css
```

## Release Process

1. Update version in version.rb
2. Update CHANGELOG.md
3. Create a GitHub Release
4. Push to RubyGems

## Questions?

Feel free to open an issue or contact maintainers directly.
