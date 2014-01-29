require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/laboratory/aliquot'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    context "when getting the location for each well" do
      include_context "create an asset"
      let(:asset_uuid) { uuid [1,2,3,4,5] }
      let(:asset_id) { wrapper.asset_id_by_uuid(asset_uuid) }
      let(:result) { wrapper.location_well_id(asset_id) }

      it "returns a hash of location to well id" do
        result.should be_a(Hash)
        result.size.should == 96
        result.keys.each { |key| key.should be_a(String) }
        result.values.each { |value| value.should be_a(Integer) }
      end
    end


    # We just test the invalid case here as the normal case it tested
    # through the update aliquots test
    context "when updating the stock plate well concentration" do
      let(:result) { wrapper.update_stock_plate_well_concentration(1, 10.0) }

      context "with no transfer request found" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::TransferRequestNotFound)
        end
      end
    end


    context "when updating aliquots" do
      include_context "create an asset"
      let(:asset_uuid) { uuid [1,2,3,4,5] }
      let(:wd_plate_before_transfer) do
        Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12)
      end
      let(:wd_plate_after_transfer) do
        Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12).tap { |plate|
          plate["E5"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 10, :type => "DNA")
          plate["E5"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 15, :type => "DNA")
          plate["E5"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 200, :type => "solvent")
          plate["F6"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 300, :type => "solvent")
          plate["F6"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 25, :type => "RNA", :out_of_bounds => {settings["out_of_bounds_concentration_key"] => 4.0})
        }
      end
      let(:wd_plate_uuid) { uuid [1,2,3,4,6] }
      let(:sample_uuids) {{
        "E5" => [uuid([1,0,0,0,1]), uuid([1,0,0,0,2])],
        "F6" => [uuid([1,0,0,0,3])]
      }}
      let(:result) { wrapper.update_aliquots(wd_plate_after_transfer, wd_plate_uuid, sample_uuids) }

      before do
        wd_plate_id = wrapper.create_asset(wd_plate_before_transfer, {})
        wrapper.create_uuid(settings["plate_type"], wd_plate_id, wd_plate_uuid)

        # Create transfer request
        stock_plate_id = wrapper.asset_id_by_uuid(asset_uuid)
        stock_b2_id = wrapper.well_id_by_location(stock_plate_id, "B2")
        wd_f6_id = wrapper.well_id_by_location(wd_plate_id, "F6")
        SequencescapeModel::Request.insert(:asset_id => stock_b2_id, :target_asset_id => wd_f6_id, :state => settings["transfer_request_state"], :request_type_id => settings["transfer_request_type_id"], :sti_type => settings["transfer_request_sti_type"])
      end

      it_behaves_like "changing table", :aliquots, 3
      it_behaves_like "changing table", :well_attributes, 2

      it "updates the well attributes of the working dilution plate" do
        result
        wd_plate_id = wrapper.asset_id_by_uuid(wd_plate_uuid)
        well_e5_id = wrapper.well_id_by_location(wd_plate_id, "E5")
        SequencescapeModel::WellAttribute[:well_id => well_e5_id].tap do |wa|
          wa.current_volume.should == 200
          wa.concentration.should be_nil
          wa.updated_at.to_s.should == date
        end

        well_f6_id = wrapper.well_id_by_location(wd_plate_id, "F6")
        SequencescapeModel::WellAttribute[:well_id => well_f6_id].tap do |wa|
          wa.current_volume.should == 300
          wa.concentration.should == 4.0
          wa.updated_at.to_s.should == date
        end
      end

      it "updates the well b2 attributes of the stock plate" do
        result
        stock_plate_id = wrapper.asset_id_by_uuid(asset_uuid)
        well_b2_id = wrapper.well_id_by_location(stock_plate_id, "B2")

        SequencescapeModel::WellAttribute[:well_id => well_b2_id].tap do |wa|
          wa.concentration.should == 4.0 * settings["stock_plate_concentration_multiplier"]
          wa.updated_at.to_s.should == date
        end
      end
    end
  end
end
