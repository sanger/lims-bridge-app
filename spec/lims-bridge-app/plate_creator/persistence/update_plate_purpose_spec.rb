require 'lims-bridge-app/plate_creator/persistence/spec_helper'
require 'lims-bridge-app/plate_creator/persistence/persistence_shared'

module Lims::BridgeApp::PlateCreator
  describe "Updating the plate purpose" do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "a plate"

    context "update the plate purpose" do
      before do
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      it "raises an exception if the plate to update cannot be found" do
        expect do
          updater.update_plate_purpose_in_sequencescape("dummy uuid", Time.now)
        end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
      end

      it "updates the plate purpose of the plate" do
        updater.update_plate_purpose_in_sequencescape(plate_uuid, Time.now)
        db[:assets].select(:assets__plate_purpose_id).join(:uuids, :resource_id => :assets__id).where(:external_id => plate_uuid).first[:plate_purpose_id].should == SequencescapeUpdater::STOCK_PLATE_PURPOSE_ID 
      end
    end
  end
end
