ENV['ANALYTICS_ENV'] = 'test'

require File.expand_path('../../config/boot', __FILE__)

require 'webmock/rspec'
require 'evented-spec'

include EventedSpec::EMSpec

WebMock.disable_net_connect!(allow_localhost: true)

callbacks = App::Initializer.instance_variable_get(:@callbacks).dup

RSpec.configure do |config|
  config.before(:each) do
    _callbacks = App::Initializer.instance_variable_get(:@callbacks)

    App::Initializer.instance_variable_set(:@callbacks, callbacks) if _callbacks.empty?
  end

  config.before(:each) { AppLogger.configure StringIO.new }

  config.before(:each) do
    expect(EM::Hiredis).to receive_message_chain(:connect, :pubsub, :psubscribe).
      and_yield(psub_channel, psub_msg)
  end

  config.formatter = :documentation
end

RSpec::Matchers.define :loggify do |*expected|
  match do
    expected.all? { |str| AppLogger.output.string.include?(str) }
  end
end
