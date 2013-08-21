module Lims::BridgeApp
  module Validator

    InvalidParameters = Class.new(StandardError) 

    def settings_validation
      SETTINGS.each do |attribute, type|
        raise InvalidParameters, "The setting #{attribute} is required" unless settings[attribute.to_s]
        raise InvalidParameters, "The setting #{attribute} must be a #{type}" unless settings[attribute.to_s].is_a?(type)
      end
      true
    end
  end
end
