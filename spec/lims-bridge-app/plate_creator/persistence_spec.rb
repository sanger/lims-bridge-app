require 'lims-bridge-app/plate_creator/spec_helper'
require 'lims-bridge-app/plate_creator/sequencescape_updater.rb'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/organization/order'

module Lims::BridgeApp::PlateCreator
  describe "Persistence on Sequencescape database" do
    include_context "test database"

    shared_examples_for "updating table for plate creation" do |table, quantity|
      it "updates the table #{table} by #{quantity} records" do
        expect do
          updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    shared_examples_for "deleting data for non stock plate" do |table, quantity|
      it "deletes data in the table #{table} by #{quantity} records" do
        expect do
          updater.delete_unassigned_plates_in_sequencescape(s2_items)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    shared_examples_for "updating table for aliquots update" do |table, quantity|
      it "updates the table #{table} by #{quantity} records" do
        expect do
          updater.update_aliquots_in_sequencescape(transfered_plate, plate_uuid, Time.now, transfered_sample_uuids)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    let(:db_settings) { YAML.load_file(File.join('config', 'database.yml'))['test'] }
    let!(:updater) do
      Class.new do 
        include SequencescapeUpdater 
        attr_accessor :db
      end.new.tap do |o|
        o.db = Sequel.connect(db_settings)
      end
    end

    # Plate
    let(:plate_uuid) { "11111111-2222-3333-4444-555555555555" }
    let(:sample_uuids) {{
      "A1" => ["11111111-0000-0000-0000-111111111111", "11111111-0000-0000-0000-222222222222"],
      "E5" => ["11111111-0000-0000-0000-333333333333", "11111111-0000-0000-0000-444444444444"]
    }}
    let(:transfered_sample_uuids) {{
      "A2" => ["11111111-0000-0000-0000-111111111111", "11111111-0000-0000-0000-222222222222"],
      "B9" => ["11111111-0000-0000-0000-555555555555", "11111111-0000-0000-0000-666666666666"],
      "E6" => ["11111111-0000-0000-0000-333333333333", "11111111-0000-0000-0000-444444444444"]
    }}
    let(:number_of_rows) { 8 }
    let(:number_of_columns) { 12 }
    let!(:plate) do
      Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows,  :number_of_columns => number_of_columns).tap do |plate|
        sample_uuids.size.times do
          plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
          plate["E5"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
        end
      end
    end
    let(:transfered_plate) do
      Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows,  :number_of_columns => number_of_columns).tap do |plate|
        sample_uuids.size.times do
          plate["A2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
          plate["B9"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
          plate["E6"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
        end
      end
    end

    # Order
    let(:stock_plate_role) { SequencescapeUpdater::STOCK_PLATES.first } 
    let(:dummy_role) { "dummy role" }
    let(:dummy_plate_uuid) { "11111111-2222-3333-4444-666666666666" }
    let(:order) do
      Lims::LaboratoryApp::Organization::Order.new.tap do |order|
        order[stock_plate_role] ||= []
        order[stock_plate_role] << Lims::LaboratoryApp::Organization::Order::Item.new({
          :uuid => plate_uuid,
          :status => SequencescapeUpdater::ITEM_DONE_STATUS
        })
        order[dummy_role] ||= []
        order[dummy_role] << Lims::LaboratoryApp::Organization::Order::Item.new({
          :uuid => dummy_plate_uuid, :status => "in_progress"
        })
      end
    end


    # Labellable
    let(:barcode_type) { "sanger-barcode" }
    let(:barcode_value) { "WD0012345A" }
    let(:labellable) do
      Lims::LaboratoryApp::Labels::Labellable.new(:name => plate_uuid, :type => "resource").tap do |labellable|
        labellable["position"] = Lims::LaboratoryApp::Labels::Labellable::Label.new({
          :type => barcode_type,
          :value => barcode_value
        })
      end
    end


    context "create a plate" do
     it_behaves_like "updating table for plate creation", :assets, 97
     it_behaves_like "updating table for plate creation", :container_associations, 96
     it_behaves_like "updating table for plate creation", :aliquots, 4
     it_behaves_like "updating table for plate creation", :uuids, 1
     it_behaves_like "updating table for plate creation", :location_associations, 1
    end


    context "update the plate purpose" do
      before do
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      it "raises an exception if the plate to update cannot be found" do
        expect do
          updater.update_plate_purpose_in_sequencescape(dummy_plate_uuid, Time.now)
        end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
      end

      it "updates the plate purpose of the plate" do
        updater.update_plate_purpose_in_sequencescape(plate_uuid, Time.now)
        db[:assets].select(:assets__plate_purpose_id).join(:uuids, :resource_id => :assets__id).where(:external_id => plate_uuid).first[:plate_purpose_id].should == SequencescapeUpdater::STOCK_PLATE_PURPOSE_ID 
      end
    end


    context "delete aliquots in sequencescape" do
      before do
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      it "raises an exception if the plate to update cannot be found" do
        expect do
          updater.delete_aliquots_in_sequencescape({dummy_plate_uuid => []}) 
        end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
      end

      it "deletes the aliquots" do
        pending
      end
    end


    context "delete non stock plate" do
      before do
        updater.create_plate_in_sequencescape(plate, dummy_plate_uuid, Time.now, sample_uuids)
      end
      let(:s2_items) { order[dummy_role] }

      it_behaves_like "deleting data for non stock plate", :assets, -97
      it_behaves_like "deleting data for non stock plate", :aliquots, -4
      it_behaves_like "deleting data for non stock plate", :container_associations, -96
      it_behaves_like "deleting data for non stock plate", :uuids, -1
    end


    context "update aliquots in sequencescape" do
      before do
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      it "raises an exception if the plate to update cannot be found" do
        expect do
          updater.update_aliquots_in_sequencescape(transfered_plate, dummy_plate_uuid, Time.now, transfered_sample_uuids) 
        end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
      end
      
      # 2 new samples are registered in the transfered plate
      it_behaves_like "updating table for aliquots update", :aliquots, 2
      it_behaves_like "updating table for aliquots update", :uuids, 0
      it_behaves_like "updating table for aliquots update", :assets, 0
      it_behaves_like "updating table for aliquots update", :container_associations, 0
    end

    
    context "set barcode to a plate" do
      before do 
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      context "invalid" do
        it "raises an exception if the plate to barcode cannot be found" do
          expect do
            updater.set_barcode_to_a_plate(labellable.class.new(:name => dummy_plate_uuid), Time.now)
          end.to raise_error(SequencescapeUpdater::PlateNotFoundInSequencescape)
        end
      end

      let(:plate_row) do
        db[:assets].join(:uuids, :resource_id => :assets__id).where(:uuids__external_id => plate_uuid).qualify.first
      end

      context "with a known prefix" do
        before do
          updater.set_barcode_to_a_plate(labellable, Time.now)
        end

        it "set the barcode to the plate" do
          plate_row[:barcode].should == "12345"
          plate_row[:barcode_prefix_id].should == 1
        end
      end

      context "with an unknown prefix" do
        before do
          updater.set_barcode_to_a_plate(labellable.tap {|l| l["position"][:value] = "AA12345A"}, Time.now)
        end

        it "set the barcode to the plate" do
          plate_row[:barcode].should == "12345"
          plate_row[:barcode_prefix_id].should == 2
        end
      end
    end
  end
end
