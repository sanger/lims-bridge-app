require 'lims-bridge-app/plate_management/persistence/spec_helper'
require 'lims-bridge-app/plate_management/persistence/persistence_shared'

module Lims::BridgeApp::PlateManagement
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
      context "check cardinality" do
        it_behaves_like "updating table for plate creation", :assets, 97
        it_behaves_like "updating table for plate creation", :container_associations, 96
        it_behaves_like "updating table for plate creation", :aliquots, 2
        it_behaves_like "updating table for plate creation", :uuids, 1
        it_behaves_like "updating table for plate creation", :location_associations, 1
        it_behaves_like "updating table for plate creation", :requests, 2
        it_behaves_like "updating table for plate creation", :well_attributes, 2
      end

      context "check values" do
        before do
          updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now.utc, sample_uuids)
        end

        it "saves the aliquot volumes in well_attributes" do
          well_attributes = db[:well_attributes].reverse_order(:id).limit(2).all
          well_attributes[0][:current_volume].should == aliquot_quantity_2
          well_attributes[1][:current_volume].should == aliquot_quantity_1
        end
      end
    end
  end
end
