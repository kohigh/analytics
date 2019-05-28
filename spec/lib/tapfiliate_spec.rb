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
  let(:get_conversion_url) { 'https://api.tapfiliate.com/1.6/conversions/?external_id=123' }

  before do
    stub_request(:get, get_conversion_url).
      with(
        headers: {
          'Accept'=>'application/json',
          'Api-Key'=>'test'
        }).
      to_return(status: get_conversion_status, body: get_conversion_response, headers: {})
  end

  context 'initial tracking' do
    context 'unsuccessful' do
      context 'get_conversion' do
        context 'error in passed params' do
          let(:get_conversion_status) { 400 }
          let(:get_conversion_response) { '[]' }

          it 'does not make retry but provide detailed info in log' do
            em do
              subject

              delayed(0.1) { is_expected.to loggify('ERROR', 'TAP GET /1.6/conversions/:123 vid:test, amount:0') }

              done(0.1)
            end
          end
        end

        context 'returns 500 so we make n retries with exponentially growing timeout' do
          let(:get_conversion_status) { 500 }
          let(:get_conversion_response) { '[]' }

          it 'does not make retry but provide detailed info in log' do
            em do
              subject

              delayed(0.2) do
                is_expected.to loggify(
                                   'WARN',
                                   'TAP:123 failed:1 with vid:test or amount:0',
                                   'TAP:123 failed:2 with vid:test or amount:0',
                                   'TAP:123 failed:3 with vid:test or amount:0',
                                   'ERROR',
                                   'TAP GET /1.6/conversions/:123 vid:test, amount:0'
                               )
                expect(a_request(:get, get_conversion_url)).to have_been_made.times(4)
              end

              done(0.2)
            end
          end
        end
      end

      context 'post_conversion' do
        let(:get_conversion_status) { 200 }
        let(:get_conversion_response) { '[]' }

        before do
          stub_request(:post, "https://tapfiliate.com/api/conversions/track/").
            with(
              body: '{"acc":"test","vid":["test"],"tid":"123","tam":0}',
              headers: {
                'Content-Type'=>'application/json'
              }).
            to_return(status: post_conversion_status, body: "", headers: {})
        end

        context 'post_conversion error in passed params' do
          let(:post_conversion_status) { 400 }

          it 'does not make retry but provide detailed info in log' do
            em do
              subject

              delayed(0.1) { is_expected.to loggify('ERROR', 'TAP POST /api/conversions/track/:123 vid:test, amount:0') }

              done(0.1)
            end
          end
        end

        context 'returns 500 so we make n retries with exponentially growing timeout' do
          let(:post_conversion_status) { 500 }
          let(:post_conversion_url) { 'https://tapfiliate.com/api/conversions/track/' }

          it 'does not make retry but provide detailed info in log' do
            em do
              subject

              delayed(0.2) do
                is_expected.to loggify(
                                   'WARN',
                                   'TAP:123 failed:1 with vid:test or amount:0',
                                   'TAP:123 failed:2 with vid:test or amount:0',
                                   'TAP:123 failed:3 with vid:test or amount:0',
                                   'ERROR',
                                   'TAP POST /api/conversions/track/:123 vid:test, amount:0'
                               )

                expect(a_request(:post, post_conversion_url).with(
                    body: '{"acc":"test","vid":["test"],"tid":"123","tam":0}',
                    headers: {'Content-Type'=>'application/json'}
                )).to have_been_made.times(4)
              end

              done(0.2)
            end
          end
        end
      end
    end

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
        to_return(status: post_commission_status, body: "", headers: {})
    end
    context 'successful' do
      let(:post_commission_status) { 200 }

      it 'create commission when user has conversion in tapfiliate' do
        em do
          subject

          delayed(0.1) { is_expected.to loggify('INFO', 'TAP:123 and vid:test tracked with amount:0') }

          done(0.1)
        end
      end
    end

    context 'unsuccessful' do
      context 'error in passed params' do
        let(:post_commission_status) { 400 }

        it 'does not make retry but provide detailed info in log' do
          em do
            subject

            delayed(0.1) { is_expected.to loggify('ERROR', 'TAP POST /1.6/conversions/1/commissions/:123 vid:test, amount:0') }

            done(0.1)
          end
        end
      end

      context 'returns 500 so we make n retries with exponentially growing timeout' do
        let(:post_commission_status) { 500 }
        let(:post_commission_url) { 'https://api.tapfiliate.com/1.6/conversions/1/commissions/' }

        it 'does not make retry but provide detailed info in log' do
          em do
            subject

            delayed(0.2) do
              is_expected.to loggify(
                                 'WARN',
                                 'TAP:123 failed:1 with vid:test or amount:0',
                                 'TAP:123 failed:2 with vid:test or amount:0',
                                 'TAP:123 failed:3 with vid:test or amount:0',
                                 'ERROR',
                                 'TAP POST /1.6/conversions/1/commissions/:123 vid:test, amount:0'
                             )
              expect(a_request(:post, post_commission_url).with(
                  body: '{"conversion_sub_amount":0}',
                  headers: {'Api-Key'=>'test', 'Content-Type'=>'application/json'}
              )).to have_been_made.times(4)

            end

            done(0.2)
          end
        end
      end
    end
  end
end
