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
        p meta, msg
      end
    end

    def disconnect
      @pubsub&.unsubscribe('analytics.*')

      @client&.close_connection
    end
  end
end