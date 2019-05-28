RSpec.describe Tapfiliate do
  subject { App.init }

  let(:psub_channel) { 'analytics.events.tap' }
  let(:psub_msg) do
    {
      tap: {
        tap_vid: 'test',
        user_id: '123',
        amount: 0
      }
    }.to_json
  end

  before do
    stub_request(:get, "https://api.tapfiliate.com/1.6/conversions/?external_id=123").
      with(
        headers: {
          'Accept'=>'application/json',
          'Api-Key'=>'test'
        }).
      to_return(status: get_conversion_status, body: get_conversion_response, headers: {})
  end

  context 'initial tracking' do

    context 'successful' do
      let(:get_conversion_status) { 200 }
      let(:get_conversion_response) { '[]' }

      before do
        stub_request(:post, "https://tapfiliate.com/api/conversions/track/").
            with(
                body: '{"acc":"test","vid":["test"],"tid":"123","tam":0}',
                headers: {
                    'Content-Type'=>'application/json'
                }).
            to_return(status: 200, body: "", headers: {})
      end

      it 'create conversion when user is not registered in tapfiliate yet' do
        em do
          subject

          delayed(0.1) { is_expected.to loggify('INFO', 'TAP:123 and vid:test tracked with amount:0') }

          done(0.1)
        end
      end
    end
  end

  context 'when conversion exists' do
    let(:get_conversion_status) { 200 }
    let(:get_conversion_response) { '[{"id":1}]' }

    before do
      stub_request(:post, "https://api.tapfiliate.com/1.6/conversions/1/commissions/").
        with(
          body: '{"conversion_sub_amount":0}',
          headers: {
            'Api-Key'=>'test',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "", headers: {})
    end

    it 'create commission when user has conversion in tapfiliate' do
      em do
        subject

        delayed(0.1) { is_expected.to loggify('INFO', 'TAP:123 and vid:test tracked with amount:0') }

        done(0.1)
      end
    end
  end
end
