require 'lims-bridge-app/decoders/gel_decoder'
require 'lims-bridge-app/decoders/spec_helper'

module Lims::BridgeApp::Decoders
  describe GelDecoder do
    context "with a gel message" do
      it_behaves_like "getting the right decoder", "gel"
    end
  end
end
