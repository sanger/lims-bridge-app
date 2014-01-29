require 'lims-bridge-app/spec_helper'
require 'lims-bridge-app/decoders/all'
require 'lims-bridge-app/base_decoder'

module Lims::BridgeApp::Decoders
  describe BaseDecoder do
    context "when decoding plate management messages" do
      it "gets the right decoder for a plate message" do
        described_class.send(:decoder_for, "plate").should == PlateDecoder 
      end

      it "gets the right decoder for a gel message" do
        described_class.send(:decoder_for, "gel").should == GelDecoder 
      end

      it "gets the right decoder for a gel message" do
        described_class.send(:decoder_for, "gel_image").should == GelImageDecoder 
      end

      it "gets the right decoder for a tube rack message" do
        described_class.send(:decoder_for, "tube_rack").should == TubeRackDecoder
      end

      it "gets the right decoder for a order message" do
        described_class.send(:decoder_for, "order").should == OrderDecoder
      end

      it "gets the right decoder for a plate transfer message" do
        described_class.send(:decoder_for, "plate_transfer").should == PlateTransferDecoder
      end

      it "gets the right decoder for a plates to plates transfer message" do
        described_class.send(:decoder_for, "transfer_plates_to_plates").should == TransferPlatesToPlatesDecoder
      end

      it "gets the right decoder for a transfer tube rack message" do
        described_class.send(:decoder_for, "tube_rack_transfer").should == TubeRackTransferDecoder
      end

      it "gets the right decoder for a move tube rack message" do
        described_class.send(:decoder_for, "tube_rack_move").should == TubeRackMoveDecoder
      end

      it "gets the right decoder for a create labellable message" do
        described_class.send(:decoder_for, "labellable").should == LabellableDecoder
      end

      it "gets the right decoder for a move tube rack message" do
        described_class.send(:decoder_for, "bulk_create_labellable").should == BulkCreateLabellableDecoder
      end

      it "gets the right decoder for an update label message" do
        described_class.send(:decoder_for, "update_label").should == UpdateLabelDecoder
      end

      it "gets the right decoder for a bulk update label message" do
        described_class.send(:decoder_for, "bulk_update_label").should == BulkUpdateLabelDecoder
      end

      it "gets the right decoder for a swap samples message" do
        described_class.send(:decoder_for, "swap_samples").should == SwapSamplesDecoder
      end

      it "raises an exception if for a unknown decoder" do
        expect do
          described_class.send(:decoder_for, "dummy")
        end.to raise_error(UndefinedDecoder)
      end
    end
  end
end
