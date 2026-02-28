# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'time'

RSpec.describe RailsMaint::Schedule do
  around do |example|
    Dir.mktmpdir('rails_maint_schedule_spec') do |tmpdir|
      Dir.chdir(tmpdir) do
        example.run
      end
    end
  end

  def write_flag(content)
    FileUtils.mkdir_p('tmp')
    File.write('tmp/maintenance_mode.txt', content)
  end

  describe '.load' do
    context 'when file does not exist' do
      it 'returns a schedule that is not active' do
        schedule = described_class.load('tmp/maintenance_mode.txt')

        expect(schedule.active?).to be false
      end
    end

    context 'with legacy plain timestamp format' do
      it 'parses the timestamp as enabled_at' do
        write_flag('2024-01-15 10:00:00 +0000')
        schedule = described_class.load('tmp/maintenance_mode.txt')

        expect(schedule.enabled_at).to be_a(Time)
        expect(schedule.active?).to be true
      end
    end

    context 'with JSON format' do
      it 'parses enabled_at, start_time, and end_time' do
        data = {
          'enabled_at' => '2024-01-15T10:00:00+00:00',
          'start_time' => '2024-01-15T10:00:00+00:00',
          'end_time' => '2024-01-15T12:00:00+00:00'
        }
        write_flag(JSON.generate(data))
        schedule = described_class.load('tmp/maintenance_mode.txt')

        expect(schedule.enabled_at).to be_a(Time)
        expect(schedule.start_time).to be_a(Time)
        expect(schedule.end_time).to be_a(Time)
      end
    end

    context 'with empty file' do
      it 'returns inactive schedule' do
        write_flag('')
        schedule = described_class.load('tmp/maintenance_mode.txt')

        expect(schedule.active?).to be false
      end
    end
  end

  describe '#active?' do
    context 'with no schedule data' do
      it 'returns false' do
        schedule = described_class.new

        expect(schedule.active?).to be false
      end
    end

    context 'with only enabled_at' do
      it 'returns true (immediate maintenance)' do
        schedule = described_class.new(enabled_at: Time.now)

        expect(schedule.active?).to be true
      end
    end

    context 'with future start_time' do
      it 'returns false before start' do
        schedule = described_class.new(
          enabled_at: Time.now,
          start_time: Time.now + 3600
        )

        expect(schedule.active?(Time.now)).to be false
      end
    end

    context 'within scheduled window' do
      it 'returns true' do
        now = Time.now
        schedule = described_class.new(
          enabled_at: now - 60,
          start_time: now - 60,
          end_time: now + 3600
        )

        expect(schedule.active?(now)).to be true
      end
    end

    context 'after scheduled window' do
      it 'returns false' do
        now = Time.now
        schedule = described_class.new(
          enabled_at: now - 7200,
          start_time: now - 7200,
          end_time: now - 3600
        )

        expect(schedule.active?(now)).to be false
      end
    end
  end

  describe '#seconds_until_end' do
    context 'with no end_time' do
      it 'returns nil' do
        schedule = described_class.new(enabled_at: Time.now)

        expect(schedule.seconds_until_end).to be_nil
      end
    end

    context 'with future end_time' do
      it 'returns positive seconds' do
        now = Time.now
        schedule = described_class.new(
          enabled_at: now,
          end_time: now + 1800
        )

        remaining = schedule.seconds_until_end(now)
        expect(remaining).to eq(1800)
      end
    end

    context 'with past end_time' do
      it 'returns nil' do
        now = Time.now
        schedule = described_class.new(
          enabled_at: now - 7200,
          end_time: now - 3600
        )

        expect(schedule.seconds_until_end(now)).to be_nil
      end
    end
  end
end
