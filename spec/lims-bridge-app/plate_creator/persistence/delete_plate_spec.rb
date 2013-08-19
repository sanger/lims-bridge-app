require 'lims-bridge-app/plate_creator/persistence/spec_helper'
require 'lims-bridge-app/plate_creator/persistence/persistence_shared'

module Lims::BridgeApp::PlateCreator
  describe "Deleting a plate" do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "a plate"

    shared_examples_for "deleting from table for plate deletion" do |table, quantity|
      it "updates the table #{table} by #{quantity} records" do
        expect do
          updater.delete_plate(plate_uuid)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    context "delete a plate" do
      before do
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      it_behaves_like "deleting from table for plate deletion", :assets, -97
      it_behaves_like "deleting from table for plate deletion", :container_associations, -96
      it_behaves_like "deleting from table for plate deletion", :uuids, -1
      it_behaves_like "deleting from table for plate deletion", :aliquots, -2
    end
  end
end
