require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/gel_decoder'

module Lims::BridgeApp::Decoders
  describe GelDecoder do
    include_context "gel message" 
    let(:result) { described_class.decode(message) }

    it_behaves_like "decoding the resource", Lims::LaboratoryApp::Laboratory::Plate
    it_behaves_like "decoding the date"
    it_behaves_like "decoding the uuid"

    it "decodes the sample uuids" do
      result[:sample_uuids].should be_a(Hash)
    end
  end
end
