# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsMaint::Webhook do
  describe '.notify' do
    context 'when url is nil' do
      it 'does nothing' do
        expect { described_class.notify(nil, event: 'maintenance.enabled') }.not_to raise_error
      end
    end

    context 'when url is empty' do
      it 'does nothing' do
        expect { described_class.notify('', event: 'maintenance.enabled') }.not_to raise_error
      end
    end

    context 'when the request succeeds' do
      it 'sends a POST request with JSON payload' do
        stub_request = nil
        allow(Net::HTTP).to receive(:new).and_wrap_original do |method, *args|
          http = method.call(*args)
          allow(http).to receive(:request) do |req|
            stub_request = req
            Net::HTTPOK.new('1.1', '200', 'OK')
          end
          http
        end

        described_class.notify('http://example.com/webhook', event: 'maintenance.enabled')

        expect(stub_request).not_to be_nil
        expect(stub_request['Content-Type']).to eq('application/json')

        body = JSON.parse(stub_request.body)
        expect(body['event']).to eq('maintenance.enabled')
        expect(body['gem']).to eq('rails_maint')
        expect(body['version']).to eq(RailsMaint::VERSION)
        expect(body['timestamp']).not_to be_nil
      end
    end

    context 'when the request fails' do
      it 'logs a warning and does not raise' do
        allow(Net::HTTP).to receive(:new).and_raise(Errno::ECONNREFUSED)
        allow(RailsMaint.logger).to receive(:warn)

        described_class.notify('http://example.com/webhook', event: 'maintenance.enabled')

        expect(RailsMaint.logger).to have_received(:warn).with(/Webhook notification failed/)
      end
    end
  end
end
