require 'lims-bridge-app/plate_creator/spec_helper'
require 'lims-bridge-app/plate_creator/json_decoder'

module Lims::BridgeApp::PlateCreator
  describe JsonDecoder do
    before do
      @decoder = Class.new do
        include JsonDecoder
      end.new
    end

    context "plate creator decoders" do
      it "gets the right decoder for a plate message" do
        @decoder.json_decoder_for("plate").should == JsonDecoder::PlateJsonDecoder 
      end

      it "gets the right decoder for a tube rack message" do
        @decoder.json_decoder_for("tube_rack").should == JsonDecoder::TubeRackJsonDecoder
      end

      it "gets the right decoder for a order message" do
        @decoder.json_decoder_for("order").should == JsonDecoder::OrderJsonDecoder
      end

      it "gets the right decoder for a plate transfer message" do
        @decoder.json_decoder_for("plate_transfer").should == JsonDecoder::PlateTransferJsonDecoder
      end

      it "gets the right decoder for a plates to plates transfer message" do
        @decoder.json_decoder_for("transfer_plates_to_plates").should == JsonDecoder::TransferPlatesToPlatesJsonDecoder
      end

      it "raises an exception if for a unknown decoder" do
        expect do
          @decoder.json_decoder_for("dummy")
        end.to raise_error(JsonDecoder::UndefinedDecoder)
      end
    end
  end
end

