require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/asset_creation_handler'

module Lims::BridgeApp::MessageHandlers
  describe AssetCreationHandler do
    let(:handler) do
      
      described_class.new(bus, log, metadata, resource, settings) 
    end
  end
end
