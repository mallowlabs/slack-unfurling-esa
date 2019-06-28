# frozen_string_literal: true

require_relative 'lib/slack_unfurling'
require_relative 'lib/esa_client'

def lambda_handler(event:, context:)
  SlackUnfurling.new(EsaClient.new).call(event)
end
