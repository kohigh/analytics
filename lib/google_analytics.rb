class GoogleAnalytics
  URL = 'http://www.google-analytics.com/collect'
  VERSION = 1
  EVENT_TYPE = 'event'

  def self.configure(tracking_id:, timeout:, **params)
    const_set('TRACKING_ID', tracking_id)
    const_set('TIMEOUT', timeout)
  end

  def initialize(client_id:, channel:, action:)
    @attempt = 1

    @client_id = client_id
    @channel = channel
    @action = action

    @params = {
      head: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Accept' => 'application/json'
      },
      body: URI.encode_www_form({
        v: VERSION,
        tid: TRACKING_ID,
        cid: client_id,
        t: EVENT_TYPE,
        ec: channel,
        ea: action
      })
    }
  end

  def track_event
    @request = EM::HttpRequest.new(URL).post(@params)

    @request.callback do
      case @request.response_header.status
      when 200 then App.info "GA:#{@client_id} tracked in #{@channel} with #{@action}"
      when 100...200, 300...500 then App.error "GA#{@request.req.path}:#{@client_id} in #{@channel} with #{@action}"
      else handle_error_response
      end
    end
    @request.errback { handle_error_response }
  end

  private

  def handle_error_response
    if @attempt < 4
      App.warn "GA:#{@client_id} failed:#{@attempt} in channel:#{@channel} with action:#{@action}"

      EM.add_timer(TIMEOUT * @attempt += 1) { track_event }
    else
      App.error "GA#{@request.req.path}:#{@client_id} channel:#{@channel}, action:#{@action}"
    end
  end
end
