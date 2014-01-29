require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/asset_creation_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'

module Lims::BridgeApp::MessageHandlers
  describe AssetCreationHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "a plate"

    let(:asset_uuid) { uuid [1,2,3,4,5] }

    after { handler.call }

    context "with a valid call" do
      include_context "sample uuids and study samples"
      let(:resource) do
        {}.tap do |resource|
          resource[:plate] = container
          resource[:uuid] = asset_uuid 
          resource[:sample_uuids] = sample_uuids
          resource[:date] = Time.now
        end
      end

      before do
        Lims::BridgeApp::SequencescapeModel::Location.insert(:name => settings["plate_location"])
        bus.should_receive(:publish).with("11111111-2222-3333-4444-555555555555")
        metadata.should_receive(:ack)
      end

      it "calls the right methods" do
        sequencescape.should_receive(:create_asset).with(container, sample_uuids).and_call_original
        sequencescape.should_receive(:create_uuid).with(settings["asset_type"], an_instance_of(Fixnum), asset_uuid)
        sequencescape.should_receive(:create_location_association).with(an_instance_of(Fixnum))
      end
    end


    context "with an invalid call" do
      context "when the resource is invalid" do
        let(:resource) do
          {}.tap do |resource|
            resource[:plate] = "dummy"
            resource[:uuid] = asset_uuid 
            resource[:sample_uuids] = sample_uuids
            resource[:date] = Time.now
          end
        end            

        it "rejects the message" do
          metadata.should_receive(:reject).with(:requeue => true)
        end
      end

      context "when a sample of the resource is not found in sequencescape" do
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
