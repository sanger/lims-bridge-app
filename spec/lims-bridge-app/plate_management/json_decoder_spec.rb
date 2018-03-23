require 'lims-bridge-app/plate_management/spec_helper'
require 'lims-bridge-app/plate_management/json_decoder'

module Lims::BridgeApp::PlateManagement
  describe JsonDecoder do
    let(:decoder) do
      Class.new do
        include JsonDecoder
      end.new
    end

    context "plate creator decoders" do
      it "gets the right decoder for a plate message" do
        decoder.json_decoder_for("plate").should == JsonDecoder::PlateJsonDecoder 
      end

      it "gets the right decoder for a gel message" do
        decoder.json_decoder_for("gel").should == JsonDecoder::GelJsonDecoder 
      end

      it "gets the right decoder for a gel message" do
        decoder.json_decoder_for("gel_image").should == JsonDecoder::GelImageJsonDecoder 
      end

      it "gets the right decoder for a tube rack message" do
        decoder.json_decoder_for("tube_rack").should == JsonDecoder::TubeRackJsonDecoder
      end

      it "gets the right decoder for a order message" do
        decoder.json_decoder_for("order").should == JsonDecoder::OrderJsonDecoder
      end

      it "gets the right decoder for a plate transfer message" do
        decoder.json_decoder_for("plate_transfer").should == JsonDecoder::PlateTransferJsonDecoder
      end

      it "gets the right decoder for a plates to plates transfer message" do
        decoder.json_decoder_for("transfer_plates_to_plates").should == JsonDecoder::TransferPlatesToPlatesJsonDecoder
      end

      it "gets the right decoder for a transfer tube rack message" do
        decoder.json_decoder_for("tube_rack_transfer").should == JsonDecoder::TubeRackTransferJsonDecoder
      end

      it "gets the right decoder for a move tube rack message" do
        decoder.json_decoder_for("tube_rack_move").should == JsonDecoder::TubeRackMoveJsonDecoder
      end

      it "gets the right decoder for a create labellable message" do
        decoder.json_decoder_for("labellable").should == JsonDecoder::LabellableJsonDecoder
      end

      it "gets the right decoder for a move tube rack message" do
        decoder.json_decoder_for("bulk_create_labellable").should == JsonDecoder::BulkCreateLabellableJsonDecoder
      end

      it "gets the right decoder for an update label message" do
        decoder.json_decoder_for("update_label").should == JsonDecoder::UpdateLabelJsonDecoder
      end

      it "gets the right decoder for a bulk update label message" do
        decoder.json_decoder_for("bulk_update_label").should == JsonDecoder::BulkUpdateLabelJsonDecoder
      end

      it "gets the right decoder for a swap samples message" do
        decoder.json_decoder_for("swap_samples").should == JsonDecoder::SwapSamplesJsonDecoder
      end

      it "raises an exception if for a unknown decoder" do
        expect do
          decoder.json_decoder_for("dummy")
        end.to raise_error(JsonDecoder::UndefinedDecoder)
      end
    end
  end
end

