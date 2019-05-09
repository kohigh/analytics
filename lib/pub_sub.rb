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

      @pubsub.psubscribe('analytics.*') do |meta, msg|
        msg = JSON.parse(msg, symbolize_names: true)

        case meta
          when /.ga/ then GoogleAnalytics.new(msg)
          # when /.amplitude/ then Amplitude.new(msg)
          # when /.intercom/ then Intercom.new(msg)
          # when /.facebookpixel/ then FacebookPixel.new(msg)
        end.track_event
      end
    end

    def disconnect
      @pubsub&.unsubscribe('analytics.*')

      @client&.close_connection
    end
  end
end