require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    context "when creating a new asset" do
      let(:result) { wrapper.create_asset(container, sample_uuids) }

      context "with an unsupported container class" do
        let(:container) { Test = Class.new.new }
        let(:sample_uuids) { {} }

        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::InvalidContainer)
        end
      end

      context "with a plate" do
        let(:container) {
          Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12).tap { |plate|
            plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 10, :type => "DNA")
            plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 15, :type => "DNA")
            plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 100, :type => "solvent")
            plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 20, :type => "solvent")
            plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 25, :type => "RNA", :out_of_bounds => {:concentration => 4.0})
            plate["C3"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 30, :type => "NA")
          }
        }

        let(:sample_uuids) {{
          "A1" => [uuid([1,0,0,0,1]), uuid([1,0,0,0,2])],
          "B2" => [uuid([1,0,0,0,3])],
          "C3" => [uuid([1,0,0,0,4])]
        }}

        before do
          (1..4).to_a.each do |i|
            SequencescapeModel::Uuid.insert(:resource_type => settings["sample_type"], :external_id => uuid([1,0,0,0,i]), :resource_id => i)
            SequencescapeModel::StudySample.insert(:sample_id => i, :study_id => 1)
          end
        end

        it_behaves_like "changing table", :assets, 97
        it_behaves_like "changing table", :container_associations, 96
        it_behaves_like "changing table", :well_attributes, 2
        it_behaves_like "changing table", :aliquots, 4
        it_behaves_like "changing table", :requests, 3

        it "saves the plate" do
          SequencescapeModel::Asset[:id => result].tap do |plate|
            plate.sti_type.should == settings["plate_type"]
            plate.plate_purpose_id.should == settings["unassigned_plate_purpose_id"]
            plate.size.should == 96
            plate.created_at.to_s.should == wrapper.date
            plate.updated_at.to_s.should == wrapper.date
          end
        end

        it "saves the 96 wells" do
          SequencescapeModel::ContainerAssociation.where(:container_id => result).all.map(&:content_id).tap do |well_ids|
            well_ids.size.should == 96
            well_ids.each do |well_id|
              SequencescapeModel::Asset[:id => well_id].tap do |well|
                well.sti_type.should == settings["well_type"]
                well.map_id.should_not be_nil
                well.created_at.to_s.should == wrapper.date
                well.updated_at.to_s.should == wrapper.date
              end
            end
          end
        end

        it "saves the solvent volume in the well attributes" do
          {"A1" => 100, "B2" => 20}.each do |location, volume|
            well_id = wrapper.well_id_by_location(result, location)
            SequencescapeModel::WellAttribute[:well_id => well_id].tap do |well|
              well.current_volume.should == volume
              well.created_at.to_s.should == wrapper.date
              well.updated_at.to_s.should == wrapper.date
            end
          end
        end

        it "saves the aliquots" do
          {"A1" => 1, "A1" => 2, "B2" => 3, "C3" => 4}.each do |location, sample_id|          
            well_id = wrapper.well_id_by_location(result, location)
            SequencescapeModel::Aliquot[:receptacle_id => well_id, :sample_id => sample_id].tap do |aliquot|
              aliquot.study_id.should == 1
              aliquot.tag_id.should == -1
              aliquot.created_at.to_s.should == wrapper.date
              aliquot.updated_at.to_s.should == wrapper.date
            end
          end
        end

        it "saves the asset requests" do
          ["A1", "B2", "C3"].each do |location|
            well_id = wrapper.well_id_by_location(result, location)
            SequencescapeModel::Request[:asset_id => well_id].tap do |request|
              request.state.should == settings["create_asset_request_state"]
              request.request_type_id.should == settings["create_asset_request_type_id"]
              request.initial_study_id.should == 1
              request.sti_type.should == settings["create_asset_request_sti_type"]
              request.created_at.to_s.should == wrapper.date
              request.updated_at.to_s.should == wrapper.date
            end
          end
        end
      end
    end


    context "when creating aliquots" do
      # As the creation of aliquots is tested through the create asset above,
      # we just here the faulty case of the method.
      context "with unknown sample" do
        let(:well_sample_uuids) { [uuid([1,0,0,0,1])] }
        let(:result) { wrapper.send(:create_aliquots, mock(:well_id), well_sample_uuids) }

        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::UnknownSample)
        end
      end
    end

    
    context "when creating an asset request" do
      # The normal case is tested in the create asset test above, we test here
      # that if the request already exists, we do not save it again.
      context "with an existing request" do
        let(:well_id) { 1 }
        let(:study_id) { 1 }
        let(:result) { wrapper.send(:create_asset_request, well_id, study_id) }
        before { wrapper.send(:create_asset_request, well_id, study_id) }
        it_behaves_like "changing table", :requests, 0 
      end
    end


    context "when creating a well attribute" do
      # The case we create a well attribute is covered in the create asset test above.
      # We test here that when we update an existing well attribute, it doesn't create
      # a new one.
      context "with an existing well attribute" do
        let(:well_id) { 1 }
        let(:result) { wrapper.send(:set_well_attributes, well_id, {
          :current_volume => 100, :concentration => 50.0, :gel_pass => "OK"
        }) }
        before { wrapper.send(:set_well_attributes, well_id, {:current_volume => 10}) }
        it_behaves_like "changing table", :well_attributes, 0

        it "updates the well attributes" do
          result
          SequencescapeModel::WellAttribute[:well_id => well_id].tap do |wa|
            wa.current_volume.should == 100
            wa.concentration.should == 50.0
            wa.gel_pass.should == "OK"
          end
        end
      end
    end
  end
end
