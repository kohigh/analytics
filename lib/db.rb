module DB
  class << self
    def configure(url:, **params)
      @url = url

      App::Initializer.callback(&method(:connect))
      App::Destructor.callback(&method(:disconnect))
    end

    def set(key, value)
      @client.set(key, value).callback do
        App.info "key:#{key} was set with value:#{value}"
      end
    end

    def get(key)
      fiber = Fiber.current

      @client.get(key).callback { |val| fiber.resume val }

      Fiber.yield
    end

    private
    def connect
      @client = EM::Hiredis.connect(@url)
    end

    def disconnect
      @client&.close_connection
    end
  end
end