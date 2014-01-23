require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/asset_deletion_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'

module Lims::BridgeApp::MessageHandlers
  describe AssetDeletionHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape wrapper"
    after { handler.call }

    context "with a valid call" do
      include_context "create an asset"
      let(:asset_uuid) { uuid [1,2,3,4,5] }
      let(:resource) do
        {}.tap do |resource|
          resource[:plate] = container
          resource[:uuid] = asset_uuid 
          resource[:sample_uuids] = sample_uuids
          resource[:date] = Time.now
        end
      end

      before do
        bus.should_receive(:publish).with("11111111-2222-3333-4444-555555555555")
        metadata.should_receive(:ack)
      end

      it "calls the delete_asset method" do
        sequencescape.should_receive(:delete_asset).with(asset_uuid).and_call_original 
      end
    end


    context "with an invalid call" do
      context "with an unknown asset" do
        include_context "a plate"
        let(:asset_uuid) { uuid [1,2,3,4,6] }
        let(:resource) do
          {}.tap do |resource|
            resource[:plate] = container
            resource[:uuid] = asset_uuid 
            resource[:sample_uuids] = sample_uuids
            resource[:date] = Time.now
          end
        end

        it "rejects the message" do
          metadata.should_receive(:reject).with(:requeue => true)
        end
      end
    end
  end
end

