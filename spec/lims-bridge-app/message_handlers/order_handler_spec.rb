require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/order_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-laboratory-app/organization/order'

module Lims::BridgeApp::MessageHandlers
  describe OrderHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape wrapper"

    let(:asset_uuid) { uuid [1,2,3,4,5] }
    let(:order_uuid) { uuid [1,2,3,4,6] }
    let(:order) do
      Lims::LaboratoryApp::Organization::Order.new.tap do |o|
        o["samples.rack.stock.dna"] = [Lims::LaboratoryApp::Organization::Order::Item.new(:uuid => asset_uuid, :status => "done")]
        o["samples.rack.stock.rna"] = [Lims::LaboratoryApp::Organization::Order::Item.new(:uuid => asset_uuid, :status => "done")]
        o["other.role"] = [Lims::LaboratoryApp::Organization::Order::Item.new(:uuid => asset_uuid, :status => "done")]
      end
    end

    let(:resource) do
      {}.tap do |r|
        r[:order] = order
        r[:uuid] = order_uuid
        r[:date] = Time.now
      end
    end


    context "when getting the plate purpose id" do
      it "returns the purpose id associated to the role in the config" do
        settings["roles_purpose_ids"].each do |role, plate_purpose_id|
          handler.send(:plate_purpose_id, role).should == plate_purpose_id
        end
      end
    end


    context "when getting the order items" do
      let(:result) { handler.send(:order_items, order) }

      it "returns only the items for which the role is defined in the config" do
        result.should be_a(Array)
        result.size.should == 2
        result.each do |item|
          item.should have_key(:role)
          item.should have_key(:items)
        end
      end
    end


    context "with a valid call" do
      after { handler.call }
      include_context "create an asset"

      before do
        2.times { bus.should_receive(:publish).with("11111111-2222-3333-4444-555555555555") }
        metadata.should_receive(:ack)
      end

      it "calls the delete_asset method" do
        sequencescape.should_receive(:update_plate_purpose).with(asset_uuid, 2).and_call_original 
        sequencescape.should_receive(:update_plate_purpose).with(asset_uuid, 183).and_call_original 
      end
    end


    context "with an invalid call" do
      context "with an unknown asset" do
        after { handler.call }

        it "rejects the message" do
          metadata.should_receive(:reject).with(:requeue => true)
        end
      end
    end
  end
end
