require 'lims-bridge-app/decoders/gel_image_decoder'
require 'lims-bridge-app/decoders/spec_helper'

module Lims::BridgeApp::Decoders
  describe GelImageDecoder do
    context "with a gel image message" do
      it_behaves_like "getting the right decoder", "gel_image"
      it_behaves_like "getting the right decoder", ""
    end
  end
end
