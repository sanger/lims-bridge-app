require 'lims-bridge-app/plate_creator/persistence/spec_helper'
require 'lims-bridge-app/plate_creator/persistence/persistence_shared'

module Lims::BridgeApp::PlateCreator
  describe "Creating a plate" do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "a plate"

    shared_examples_for "updating table for plate creation" do |table, quantity|
      it "updates the table #{table} by #{quantity} records" do
        expect do
          updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now.utc, sample_uuids)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    context "create a plate" do
      it_behaves_like "updating table for plate creation", :assets, 97
      it_behaves_like "updating table for plate creation", :container_associations, 96
      it_behaves_like "updating table for plate creation", :aliquots, 2
      it_behaves_like "updating table for plate creation", :uuids, 1
      it_behaves_like "updating table for plate creation", :location_associations, 1
      it_behaves_like "updating table for plate creation", :requests, 2
    end
  end
end
