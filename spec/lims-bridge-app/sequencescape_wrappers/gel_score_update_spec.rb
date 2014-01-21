require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'
require 'lims-quality-app/gel-image/gel_image'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"


    shared_context "create a gel" do
      let(:gel) { Lims::LaboratoryApp::Laboratory::Gel.new(:number_of_rows => 8, :number_of_columns => 12) }
      let(:gel_uuid) { uuid [1,2,3,4,6] }

      before do
        gel_id = wrapper.create_asset(gel, {})
        wrapper.create_uuid(settings["gel_type"], gel_id, gel_uuid)
      end
    end


    context "when updating gel scores" do
      include_context "create a gel"

      # The stock plate
      include_context "create an asset"
      let(:asset_uuid) { uuid [1,2,3,4,5] }

      let(:scores) {{"C1" => "pass", "C2" => "fail", "C3" => "degraded", "C4" => "partially degraded"}}
      let(:gel_image) { Lims::QualityApp::GelImage.new(:gel_uuid => gel_uuid, :scores => scores) }
      let(:result) { wrapper.update_gel_scores(gel_image) }

      let(:working_dilution_well_b1_id) { SequencescapeModel::Asset.reverse(:id).first.id + 1 }
      let(:working_dilution_well_b2_id) { working_dilution_well_b1_id + 1 }
      let(:working_dilution_well_b3_id) { working_dilution_well_b2_id + 1 }
      let(:working_dilution_well_b4_id) { working_dilution_well_b3_id + 1 }

      # We mock the transfers from a stock plate, to a working dilution plate and
      # from the working dilution plate to the gel.
      before do
        stock_plate_id = wrapper.asset_id_by_uuid(asset_uuid)
        gel_id = wrapper.asset_id_by_uuid(gel_uuid)
        (1..4).to_a.each do |i|
          # Stock well to working dilution transfer
          stock_well_id = wrapper.well_id_by_location(stock_plate_id, "A#{i}")
          SequencescapeModel::Request.insert({
            :asset_id => stock_well_id, 
            :target_asset_id => send("working_dilution_well_b#{i}_id"),
            :sti_type => settings["transfer_request_sti_type"],
            :state => settings["transfer_request_state"]
          })

          # Working dilution to gel
          gel_well_id = wrapper.well_id_by_location(gel_id, "C#{i}")
          SequencescapeModel::Request.insert({
            :asset_id => send("working_dilution_well_b#{i}_id"),
            :target_asset_id => gel_well_id,
            :sti_type => settings["transfer_request_sti_type"],
            :state => settings["transfer_request_state"]
          })
        end
      end

      it "updates the well attributes of the stock plate" do
        result
        stock_plate_id = wrapper.asset_id_by_uuid(asset_uuid)

        ["OK", "fail", "Degraded", "Partially degraded"].each_with_index do |score, i|
          well_id = wrapper.well_id_by_location(stock_plate_id, "A#{i+1}")
          SequencescapeModel::WellAttribute[:well_id => well_id].tap do |wa|
            wa.gel_pass.should == score
            wa.created_at.to_s.should == date
            wa.updated_at.to_s.should == date
          end
        end
      end
    end
  end
end
