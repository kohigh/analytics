# frozen_string_literal: true

class Tapfiliate
  include EM::Deferrable

  def self.configure(account_id:, api_key:, timeout:, **params)
    const_set('ACCOUNT_ID', account_id)
    const_set('API_KEY', api_key)
    const_set('TIMEOUT', timeout)
  end

  def initialize(tap_vid:, user_id:, amount:)
    @attempt = 1

    @user_id = user_id
    @tap_vid = tap_vid
    @amount = amount

    @url, @params = if conversion_id = DB.get("tap_conversion#{@user_id}")
                      commission_params(conversion_id)
                    else
                      callback { |id:, **params| DB.set("tap_conversion#{@user_id}", id) }

                      conversion_params
                    end

    callback { App.info "TAP:#{@user_id} and vid:#{@tap_vid} tracked with amount:#{@amount}" }
  end

  def track_event
    @request = EM::HttpRequest.new(@url).post(@params)

    @request.callback do
      case @request.response_header.status
      when 200 then succeed(JSON.parse(@request.response, symbolize_names: true))
      when 100...200, 300...500 then App.error "TAP#{@request.req.path}:#{@user_id} vid:#{@tap_vid}, amount:#{@amount}"
      else handle_error_response
      end
    end
    @request.errback { handle_error_response }
  end

  private

  def handle_error_response
    if @attempt < 4
      EM.add_timer(TIMEOUT * @attempt += 1) { track_event }

      App.warn "TAP:#{@user_id} failed#{@attempt} with vid:#{@tap_vid} or amount:#{@amount}"
    else
      App.error "TAP#{@request.req.path}:#{@user_id} vid:#{@tap_vid}, amount:#{@amount}"
    end
  end

  def conversion_params
    [
      'https://tapfiliate.com/api/conversions/track/',
      {
        head: {
          'Content-Type' => 'application/json'
        },
        body: {
          acc: ACCOUNT_ID,
          vid: [@tap_vid],
          tid: @user_id,
          tam: @amount
        }.to_json
      }
    ]
  end

  def commission_params(conversion_id)
    [
      "https://api.tapfiliate.com/1.6/conversions/#{conversion_id}/commissions/",
      {
        head: {
          'Content-Type' => 'application/json',
          'Api-Key' => API_KEY
        },
        body: { conversion_sub_amount: @amount }.to_json
      }
    ]
  end
end
