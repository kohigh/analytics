class Amplitude
  URL = 'https://api.amplitude.com/httpapi'

  def self.configure(api_key:, timeout:, **params)
    const_set('API_KEY', api_key)
    const_set('TIMEOUT', timeout)
  end

  def initialize(user_id:, event_type:, **params)
    @attempt = 1

    @user_id = user_id
    @event_type = event_type
    @params = params

    @params = {
      head: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Accept' => 'application/json',
      },
      body: URI.encode_www_form({
        api_key: API_KEY,
        event:[
          {
            "user_id": user_id,
            "event_type": event_type
          }
        ].to_json
      })
    }
  end

  def track_event
    @request = EM::HttpRequest.new(URL).post(@params)

    @request.callback do
      case @request.response_header.status
      when 200 then App.info "AMP:#{@user_id} tracked with #{@event_type}"
      when 100...200, 300...500 then App.error "AMP:#{@user_id} #{@request.req.path} with #{@event_type}"
      else handle_error_response
      end
    end

    @request.errback { App.info handle_error_response }
  end

  private

  def handle_error_response
    if @attempt < 4
      EM.add_timer(TIMEOUT * @attempt += 1) { track_event }

      App.warn "AMP:#{@user_id} failed with :#{@event_type}"
    else
      App.error "AMP:#{@user_id} #{@request.req.path}, event:#{@event_type}"
    end
  end
end
