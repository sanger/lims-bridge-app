require 'lims-bridge-app/plate_creator/persistence/spec_helper'
require 'lims-bridge-app/plate_creator/persistence/persistence_shared'

module Lims::BridgeApp::PlateCreator
  describe "Deleting aliquots" do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "a plate"

    context "delete aliquots in sequencescape" do
      before do
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      it "raises an exception if the plate to update cannot be found" do
        expect do
          updater.delete_aliquots_in_sequencescape({"dummy uuid" => []}) 
        end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
      end

      it "deletes the aliquots" do
        expect do
          updater.delete_aliquots_in_sequencescape(plate_uuid => [:A1, :E5]) 
        end.to change { db[:aliquots].count }.by(-4)
      end
    end
  end
end
