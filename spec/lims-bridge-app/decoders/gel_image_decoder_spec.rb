require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/gel_image_decoder'

module Lims::BridgeApp::Decoders
  describe GelImageDecoder do
    include_context "gel image message"

    context "when creating a gel image" do
      let(:result) { described_class.decode(create_message) }

      it_behaves_like "decoding the resource", Lims::QualityApp::GelImage
      it_behaves_like "decoding the date"
      it_behaves_like "decoding the uuid"

      it "decodes the gel image" do
        result[:gel_image].gel_uuid.should == "11111111-2222-3333-4444-666666666666"
      end
    end

    context "when updating a gel image" do
      let(:result) { described_class.decode(update_action_message) }

      it_behaves_like "decoding the resource", Lims::QualityApp::GelImage
      it_behaves_like "decoding the date"
      it_behaves_like "decoding the uuid"

      it "decodes the gel image" do
        result[:gel_image].gel_uuid.should == "11111111-2222-3333-4444-666666666666"
        result[:gel_image].scores.should == {"A1"=>"pass", "B2"=>"fail", "C3"=>"degraded", "D4"=>"partially degraded"}
      end
    end
  end
end
