require 'lims-bridge-app/plate_management/persistence/spec_helper'
require 'lims-bridge-app/plate_management/persistence/persistence_shared'

module Lims::BridgeApp::PlateManagement
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

      context "errored call" do
        it "raises an exception if the plate to update cannot be found" do
          expect do
            updater.update_aliquots_in_sequencescape(transfered_plate, "dummy uuid", Time.now, transfered_sample_uuids) 
          end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
        end
      end

      context "check cardinality" do
        # 2 new aliquots
        it_behaves_like "updating table for aliquots update", :aliquots, 2
        it_behaves_like "updating table for aliquots update", :uuids, 0
        it_behaves_like "updating table for aliquots update", :assets, 0
        it_behaves_like "updating table for aliquots update", :container_associations, 0
        it_behaves_like "updating table for aliquots update", :requests, 2
        it_behaves_like "updating table for aliquots update", :well_attributes, 2
      end

      context "check values" do
        before do
          updater.update_aliquots_in_sequencescape(transfered_plate, plate_uuid, Time.now, transfered_sample_uuids)
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
