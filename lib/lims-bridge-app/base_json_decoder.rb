module Lims::BridgeApp
  module BaseJsonDecoder
    # Exception raised if a decoder for a specific 
    # model is undefined.
    class UndefinedDecoder < StandardError
    end

    # Get the decoder for the model in parameters
    # @param [String] model
    def json_decoder_for(model)
      begin
        decoder = "#{model.to_s.capitalize.gsub(/_./) {|p| p[1].upcase}}JsonDecoder"
        self.class.const_get(decoder)
      rescue NameError => e
        raise UndefinedDecoder, "#{decoder} is undefined"
      end
    end 
  end
end
