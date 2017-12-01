# frozen_string_literal: true

module ResponseHelpers
  def guid_from_response(response)
    JSON.parse(response.body)['guid']
  end
end
