require 'lims-bridge-app/plate_management/message_handlers/spec_helper'
require 'lims-bridge-app/plate_management/message_handlers/order_handler'
require 'lims-laboratory-app/organization/order'

module Lims::BridgeApp::PlateManagement::MessageHandler
  describe OrderHandler do
    include_context "plate settings"

    let(:empty_order) { Lims::LaboratoryApp::Organization::Order.new }
    let(:item_uuid) { "11111111-2222-3333-4444-555555555555" }
    let(:item_status) { "done" }
    let(:order_item) { Lims::LaboratoryApp::Organization::Order::Item.new(:uuid => item_uuid, :status => item_status) }

    let(:bus) { mock(:bus).tap { |b| b.stub(:publish) }}
    let(:metadata) { mock(:metadata).tap { |b| b.stub(:ack); b.stub(:reject) }}
    let(:log) { mock(:log).tap { |b| b.stub(:info) }}
    let(:handler) { OrderHandler.new(nil, bus, log, metadata, {:order => order}, settings) }

    shared_examples_for "finding processable items" do |roles|
      it "finds items which match patterns" do
        result = handler.send(:plate_items, order)
        result.should be_a(Array)
        result.size.should == roles.size
        result.zip(roles).each do |item, role|
          item[:role].should == role
        end
      end
    end

    shared_examples_for "updating the plate with the right plate purpose" do |plate_purposes|
      it "updates the plates in sequencescape with the right plate purposes" do
        plate_purposes.each do |purpose_id|
          handler.should_receive(:update_plate_purpose_in_sequencescape).with(item_uuid, anything, purpose_id)
        end
        handler.send(:_call_in_transaction)
      end
    end

    context "Order with non used items" do
      let(:order) do
        empty_order["dummy"] = []
        empty_order["dummy"] << order_item
        empty_order
      end

      it_behaves_like "finding processable items", []

      it "does not update any plate" do
        handler.should_not_receive(:update_plate_purpose_in_sequencescape) 
        handler.send(:_call_in_transaction)
      end
    end

    context "Order with a stock plate dna item" do
      let(:order) do
        empty_order["samples.rack.stock.dna"] = []
        empty_order["samples.rack.stock.dna"] << order_item
        empty_order
      end

      it_behaves_like "finding processable items", ["samples.rack.stock.dna"]
      it_behaves_like "updating the plate with the right plate purpose", [2]
    end

    context "Order with a stock plate dna item and a working dilution item" do
      let(:order) do
        empty_order["samples.rack.stock.dna"] = []
        empty_order["samples.rack.stock.dna"] << order_item
        empty_order["samples.qc.nx_nanodrop.working_dilution_rna"] = []
        empty_order["samples.qc.nx_nanodrop.working_dilution_rna"] << order_item
        empty_order
      end

      it_behaves_like "finding processable items", ["samples.rack.stock.dna", "samples.qc.nx_nanodrop.working_dilution_rna"]
      it_behaves_like "updating the plate with the right plate purpose", [2, 1]
    end

    context "Order with a stock plate dna item and a working dilution item" do
      let(:order) do
        empty_order["samples.rack.stock.dna"] = []
        empty_order["samples.rack.stock.dna"] << order_item
        empty_order["samples.rack.stock.rna"] = []
        empty_order["samples.rack.stock.rna"] << order_item
        empty_order["samples.qc.nx_nanodrop.working_dilution_rna"] = []
        empty_order["samples.qc.nx_nanodrop.working_dilution_rna"] << order_item
        empty_order
      end

      it_behaves_like "finding processable items", ["samples.rack.stock.dna", "samples.rack.stock.rna", "samples.qc.nx_nanodrop.working_dilution_rna"]
      it_behaves_like "updating the plate with the right plate purpose", [2, 183, 1]
    end

    context "Order with volume checked stock rna racks" do
      let(:order) do
        empty_order["samples.qc.nx_nanodrop.volume_checked_stock_rack_rna"] = []
        empty_order["samples.qc.nx_nanodrop.volume_checked_stock_rack_rna"] << order_item
        empty_order["samples.qc.nx_nanodrop.volume_checked_stock_rack_rna.batched"] = []
        empty_order["samples.qc.nx_nanodrop.volume_checked_stock_rack_rna.batched"] << order_item
        empty_order
      end

      it_behaves_like "finding processable items", ["samples.qc.nx_nanodrop.volume_checked_stock_rack_rna", "samples.qc.nx_nanodrop.volume_checked_stock_rack_rna.batched"]
      it_behaves_like "updating the plate with the right plate purpose", [183, 183]
    end
  end
end
