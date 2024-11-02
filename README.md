# RailsMaint

RailsMaint is a simple and customizable maintenance mode gem for Rails applications. It allows you to display a sleek maintenance page to your users during maintenance work.

## Features

- 🚀 Easy setup and usage
- 🎨 Customizable, modern maintenance page design
- 🌍 Multi-language support (English and Turkish)
- 🔒 IP whitelist support
- 💻 Simple CLI commands
- 🎯 Rails Middleware integration

## Installation

1. Add this line to your application's Gemfile:

```
gem 'rails_maint'
```

2. Execute:

```
bundle install
```

3. Add the middleware to your Rails application's `config/application.rb`:

```
config.middleware.use RailsMaint::Middleware
```

## Usage

### Installing the Gem

```
# For English (default)
rails_maint install

# For Turkish
rails_maint install --locale=tr
```

This command creates the following files:
- `config/rails_maint.yml` - Configuration file
- `config/locales/rails_maint.{locale}.yml` - Language file

### Managing Maintenance Mode

```
# To enable maintenance mode
rails_maint enable

# To disable maintenance mode
rails_maint disable

# To remove all files
rails_maint uninstall
```

## Configuration

You can customize your settings in `config/rails_maint.yml`:

```
# Default language setting
locale: en

# IP addresses allowed to access
white_listed_ips:
- 127.0.0.1
- ::1
# Add your IPs
# - 192.168.1.1
```

## Language Support

Language files are stored in the `config/locales` directory. You can customize existing translations or add new languages:

```
# config/locales/rails_maint.en.yml
en:
rails_maint:
title: "System Maintenance"
description: "Our system is currently being updated..."
estimated_time: "Estimated time: 1 hour"
```

```
# config/locales/rails_maint.tr.yml
tr:
rails_maint:
title: "Sistem Bakımda"
description: "Sistemimiz şu anda güncelleniyor..."
estimated_time: "Tahmini süre: 1 saat"
```

## How IP Whitelist Works

- When maintenance mode is active, IPs in the whitelist can access the site normally
- All other IPs will see the maintenance page
- If behind a proxy, the gem checks the X-Forwarded-For header
- Each IP should be added to the configuration file

## Development

1. Clone the repository
2. Install dependencies: `bundle install`
3. Run tests: `bundle exec rspec`

## Customizing the Maintenance Page

The maintenance page template can be customized by creating your own version in `public/maintenance.html`. The default template includes:

- Responsive design
- Animated maintenance icon
- Clean and modern layout
- Estimated time display

## Rails Version Support

- Rails 6.0 or higher
- Ruby 2.6 or higher

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing_feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing_feature`)
5. Create a Pull Request

## Best Practices

- Always test your changes
- Follow the Ruby Style Guide
- Write meaningful commit messages
- Add tests for new features
- Update documentation when needed

## Common Issues

### IP Whitelist Not Working

Make sure your IP is correctly added to the configuration file and you're not behind an unexpected proxy.

### Language Not Changing

Verify that:
1. The locale file exists
2. The locale is correctly set in the configuration
3. The Rails server was restarted after changes

## Security

- The gem uses Rails' built-in security features
- IP validation is performed securely
- No sensitive information is exposed

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Contact & Support

- GitHub Issues: [rails_maint/issues](https://github.com/codescaptain/rails_maint/issues)
- Email: [ahmet-57-@hotmail.com](mailto:ahmet-57-@hotmail.com)

## Credits

Developed and maintained by [CodesCaptain](https://github.com/codescaptain)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.