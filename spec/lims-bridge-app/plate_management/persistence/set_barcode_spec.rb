require 'lims-bridge-app/plate_management/persistence/spec_helper'
require 'lims-bridge-app/plate_management/persistence/persistence_shared'

module Lims::BridgeApp::PlateManagement
  describe "Setting a barcode to a plate" do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "a plate"
    include_context "a labellable"

    context "set barcode to a plate" do
      before do 
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
      end

      let(:resource_uuid) { plate_uuid }

      context "invalid" do
        it "raises an exception if the plate to barcode cannot be found" do
          expect do
            updater.set_barcode_to_a_plate(labellable.class.new(:name => "dummy uuid"), Time.now)
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

        context "with a dashed uuid" do
          it "set the barcode to the plate" do
            plate_row[:name].should == "Plate 12345"
            plate_row[:barcode].should == "12345"
            plate_row[:barcode_prefix_id].should == 1
          end
        end

        context "with a non dashed uuid" do
          let(:resource_uuid) { "11111111222233334444555555555555" }

          it "set the barcode to the plate" do
            plate_row[:name].should == "Plate 12345"
            plate_row[:barcode].should == "12345"
            plate_row[:barcode_prefix_id].should == 1           
          end
        end
      end

      context "with a Working Dilution plate" do
        before do
          updater.set_barcode_to_a_plate(labellable, Time.now)
        end

        let(:barcode_value) { "WD0012345A" }

        context "with a dashed uuid" do
          it "set the barcode to the plate" do
            plate_row[:name].should == "Working dilution 12345"
            plate_row[:barcode].should == "12345"
            plate_row[:barcode_prefix_id].should == 2
          end
        end
      end

      context "with an unknown valid prefix" do
        before do
          updater.set_barcode_to_a_plate(labellable.tap {|l| l["position"][:value] = "NR12345A"}, Time.now)
        end

        it "set the barcode to the plate" do
          plate_row[:name].should == "Plate 12345"
          plate_row[:barcode].should == "12345"
          plate_row[:barcode_prefix_id].should == 2
        end
      end

      context "with an invalid prefix" do
        it "raises an InvalidBarcode error" do
          expect do
          updater.set_barcode_to_a_plate(labellable.tap {|l| l["position"][:value] = "AA12345A"}, Time.now)
          end.to raise_error(SequencescapeUpdater::InvalidBarcode)
        end
      end
    end
  end
end
