class Tapfiliate
  URL = 'https://tapfiliate.com/api/conversions/track/'

  def self.configure(account_id:, timeout:, **params)
    const_set('ACCOUNT_ID', account_id)
    const_set('TIMEOUT', timeout)
  end

  def initialize(tap_vid:, user_id:, amount:)
    @attempt = 1

    @user_id = user_id
    @tap_vid = tap_vid
    @amount = amount

    @params = {
      head: {
        'Content-Type' => 'application/json'
      },
      body: {
        acc: ACCOUNT_ID,
        vid: [tap_vid],
        tid: user_id,
        tam: amount
      }.to_json
    }
  end

  def track_event
    @request = EM::HttpRequest.new(URL).post(@params)

    @request.callback do
      case @request.response_header.status
      when 200 then App.info "TAP:#{@user_id} and vid:#{@tap_vid} tracked with amount:#{@amount}"
      when 100...200, 300...500 then App.warn "TAP:#{@user_id} problems with vid:#{@tap_vid} or amount:#{@amount}"
      else handle_error_response
      end
    end
    @request.errback { handle_error_response }
  end

  private

  def handle_error_response
    App.warn "TAP:#{@user_id} failed#{@attempt} with vid:#{@tap_vid} or amount:#{@amount}"

    EM.add_timer(TIMEOUT * @attempt += 1) { track_event } if @attempt < 4
  end
end
