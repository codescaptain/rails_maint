# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsMaint::Instrumentation do
  describe '.instrument' do
    context 'when ActiveSupport::Notifications is not defined' do
      it 'does nothing and does not raise' do
        expect { described_class.instrument('test_event', foo: 'bar') }.not_to raise_error
      end
    end

    context 'when ActiveSupport::Notifications is defined' do
      before do
        stub_const('ActiveSupport::Notifications', Class.new do
          def self.instrument(event, payload = {})
            # stub
          end
        end)
      end

      it 'calls ActiveSupport::Notifications.instrument with namespaced event' do
        allow(ActiveSupport::Notifications).to receive(:instrument)

        described_class.instrument('request_blocked', remote_ip: '1.2.3.4')

        expect(ActiveSupport::Notifications).to have_received(:instrument)
          .with('request_blocked.rails_maint', remote_ip: '1.2.3.4')
      end
    end
  end
end
