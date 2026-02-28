# frozen_string_literal: true

module RailsMaint
  class StatusPrinter
    def print
      config = ConfigLoader.load
      print_maintenance_status
      puts ''
      print_config_status(config)
    end

    private

    def print_maintenance_status
      maintenance_file = 'tmp/maintenance_mode.txt'

      unless File.exist?(maintenance_file)
        puts 'Status: DISABLED'
        return
      end

      schedule = RailsMaint::Schedule.load(maintenance_file)
      puts schedule.active? ? 'Status: ENABLED' : 'Status: ENABLED (not currently active — outside scheduled window)'
      print_schedule_details(schedule)
    end

    def print_schedule_details(schedule)
      puts "  Enabled at: #{schedule.enabled_at}" if schedule.enabled_at
      puts "  Start time: #{schedule.start_time}" if schedule.start_time
      puts "  End time:   #{schedule.end_time}" if schedule.end_time

      return unless schedule.end_time

      remaining = schedule.seconds_until_end
      puts "  Remaining:  #{remaining}s" if remaining
    end

    def print_config_status(config)
      puts "Locale: #{config['locale'] || 'en'}"
      print_list('Whitelisted IPs', config['white_listed_ips'])
      print_list('Bypass paths', config['bypass_paths'])
      puts "Retry-After: #{config['retry_after'] || 3600}s"
      puts "Custom page: #{config['custom_page'] || 'none'}"
      puts "Webhook URL: #{config['webhook_url'] || 'none'}"
    end

    def print_list(label, items)
      items ||= []
      puts "#{label}: #{items.empty? ? 'none' : items.join(', ')}"
    end
  end
end
