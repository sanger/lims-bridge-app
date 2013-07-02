require 'lims-bridge-app/plate_creator/persistence/spec_helper'
require 'lims-bridge-app/plate_creator/persistence/persistence_shared'

module Lims::BridgeApp::PlateCreator
  describe "Updating aliquots" do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "a plate"
    include_context "a transfered plate"

    shared_examples_for "updating table for aliquots update" do |table, quantity|
      it "updates the table #{table} by #{quantity} records" do
        expect do
          updater.update_aliquots_in_sequencescape(transfered_plate, plate_uuid, Time.now, transfered_sample_uuids)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    context "update aliquots in sequencescape" do
      before do
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      it "raises an exception if the plate to update cannot be found" do
        expect do
          updater.update_aliquots_in_sequencescape(transfered_plate, "dummy uuid", Time.now, transfered_sample_uuids) 
        end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
      end

      # 2 new samples are registered in the transfered plate
      it_behaves_like "updating table for aliquots update", :aliquots, 2
      it_behaves_like "updating table for aliquots update", :uuids, 0
      it_behaves_like "updating table for aliquots update", :assets, 0
      it_behaves_like "updating table for aliquots update", :container_associations, 0
    end
  end
end
