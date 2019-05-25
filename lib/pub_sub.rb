# frozen_string_literal: true
module PubSub
  class << self
    def configure(url:, **params)
      @url = url

      App::Initializer.callback(&method(:connect))
      App::Destructor.callback(&method(:disconnect))
    end

    private

    def connect
      @client = EM::Hiredis.connect(@url)

      @pubsub = @client.pubsub

      @pubsub.psubscribe('analytics.events.*') do |channel_name, msg|
        msg = JSON.parse(msg, symbolize_names: true)

        channel_name.split('.')[2..-1].each do |service_name|
          case service_name
          when 'ga' then GoogleAnalytics.new(msg[:ga])
          when 'tap' then Fiber.new { Tapfiliate.new(msg[:tap]).track_event }.resume
          # when 'amp' then Amplitude.new(msg)
          # when 'int' then Intercom.new(msg)
          # when 'fbp' then FacebookPixel.new(msg)
          end&.track_event
        end
      end
    end

    def disconnect
      @pubsub&.unsubscribe('analytics.*')

      @client&.close_connection
    end
  end
end
