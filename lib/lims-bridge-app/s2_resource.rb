module Lims::BridgeApp
  module S2Resource
    # Decode the json message and return a S2 core resource
    # and additional informations like its uuid in S2.
    # @param [String] message
    # @return [Hash] S2 core resource and uuid
    # @example
    # {:plate => Lims::Core::Laboratory::Plate, :uuid => xxxx}
    def s2_resource(message)
      body = JSON.parse(message)
      
      action = body.delete("action")
      date = Time.parse(body.delete("date"))
      user = body.delete("user")
      options = {:action => action, :date => date, :user => user}

      model = body.keys.first
      json_decoder_for(model).call(body, options)
    end
  end
end
