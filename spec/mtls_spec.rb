require 'spec_helper'

# TODO: (pego) rename properly (also this file)
describe 'bits-service' do
  context 'Mutual TLS' do
    context 'No client certificate sent' do
      it 'returns a 40x' do
        response = make_get_request '/packages/some-irrelevant-guid'
        puts response.code
        # expect(response.code).to eq 403
      end
    end
  end
end
