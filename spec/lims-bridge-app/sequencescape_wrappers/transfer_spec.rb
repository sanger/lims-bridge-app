require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    context "when creating an asset link" do
      let(:ancestor_id) { 1 }
      let(:descendant_id) { 2 }
      let(:result) { wrapper.create_asset_link(ancestor_id, descendant_id) } 

      context "when it doesn't exist in the database" do
        it_behaves_like "changing table", :asset_links, 1

        it "saves the asset link" do
          asset_link_id = result.id
          SequencescapeModel::AssetLink[:id => asset_link_id].tap do |al|
            al.ancestor_id.should == ancestor_id
            al.descendant_id.should == descendant_id
            al.direct.should == 1
            al.count.should == 1
            al.created_at.to_s.should == date
            al.updated_at.to_s.should == date
          end
        end
      end

      context "when it already exists in the database" do
        before { wrapper.create_asset_link(ancestor_id, descendant_id) }
        it_behaves_like "changing table", :asset_links, 0
      end
    end


    context "when creating a new transfer request" do
      let(:source_well_id) { 1 }
      let(:target_well_id) { 2 }
      let(:result) { wrapper.create_transfer_request(source_well_id, target_well_id) }

      it_behaves_like "changing table", :requests, 1

      it "saves the transfer request" do
        request_id = result.id
        SequencescapeModel::Request[:id => request_id].tap do |r|
          r.created_at.to_s.should == date
          r.updated_at.to_s.should == date
          r.state.should == settings["transfer_request_state"]
          r.request_type_id.should == settings["transfer_request_type_id"]
          r.asset_id.should == source_well_id
          r.target_asset_id.should == target_well_id
          r.sti_type.should == settings["transfer_request_sti_type"]
        end
      end
    end


    context "when moving well" do
      let(:asset_uuid) { uuid [1,2,3,4,5] }
      let(:source_uuid) { asset_uuid }
      include_context "create an asset"

      let(:target_uuid) { uuid [1,2,3,4,6] }
      let(:target_plate) { Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12) }

      let(:source_location) { "A1" }
      let(:target_location) { "B5" }
      let(:move_well) { wrapper.move_well(source_uuid, source_location, target_uuid, target_location) }      

      let(:source_id) { wrapper.asset_id_by_uuid(source_uuid) }
      let(:target_id) { wrapper.asset_id_by_uuid(target_uuid) }
      let(:source_well_a1_id) { wrapper.well_id_by_location(source_id, "A1") }
      let(:target_well_b5_id) { wrapper.well_id_by_location(target_id, "B5") }

      before do
        plate_id = wrapper.create_asset(target_plate, {})
        wrapper.create_uuid(settings["plate_type"], plate_id, target_uuid)
        source_well_a1_id
        target_well_b5_id
        move_well
      end

      it "moves the source plate well A1 to the target plate well B5" do
        SequencescapeModel::Asset[:id => source_well_a1_id].tap do |a1|
          # the source well a1 is now attached to the position b5 in the target plate
          a1.map_id.should == wrapper.map_id(96, "B5")
          a1.updated_at.to_s.should == date
        end
        SequencescapeModel::ContainerAssociation[:container_id => target_id, :content_id => source_well_a1_id].should_not be_nil
        SequencescapeModel::ContainerAssociation[:container_id => source_id, :content_id => source_well_a1_id].should be_nil
      end

      it "moves the target plate well B5 to the source plate well A1" do
        SequencescapeModel::Asset[:id => target_well_b5_id].tap do |b5|
          # the target well b5 is now attached to the position a1 in the source plate
          b5.map_id.should == wrapper.map_id(96, "A1")
          b5.updated_at.to_s.should == date
        end
        SequencescapeModel::ContainerAssociation[:container_id => target_id, :content_id => target_well_b5_id].should be_nil
        SequencescapeModel::ContainerAssociation[:container_id => source_id, :content_id => target_well_b5_id].should_not be_nil       
      end
    end


    context "when swapping samples" do
      pending
    end
  end
end
