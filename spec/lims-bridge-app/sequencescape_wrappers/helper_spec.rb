require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    context "when creating a new uuid" do
      let(:resource_type) { "Plate" }
      let(:resource_id) { 1 }
      let(:external_id) { uuid([1,2,3,4,5]) }
      let(:result) { wrapper.create_uuid(resource_type, resource_id, external_id) }

      it "saves the new uuid" do
        result.id.should_not be_nil
      end

      it "reloads the new uuid" do
        SequencescapeModel::Uuid[:id => result.id].tap do |uuid|
          uuid.resource_type.should == resource_type
          uuid.resource_id.should == resource_id
          uuid.external_id.should == external_id
        end
      end
    end


    context "when creating a new location association" do
      let(:asset_id) { 123 }
      let(:result) { wrapper.create_location_association(asset_id) }

      context "with a known plate location" do
        before do
          SequencescapeModel::Location.insert(:name => settings["plate_location"])
        end

        it "saves the location association" do
          result.id.should_not be_nil 
        end

        it "reloads the new location association" do
          SequencescapeModel::LocationAssociation[:id => result.id].tap do |la|
            la.locatable_id.should == asset_id
            la.location_id.should == SequencescapeModel::Location[:name => settings["plate_location"]].id
          end
        end
      end

      context "with an unknown location" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::UnknownLocation)
        end
      end
    end


    context "when getting a map id" do
      let(:asset_size) { 96 }
      let(:result) { wrapper.map_id(asset_size, location) }

      context "with a known map location" do
        let(:location) { "A1" }        

        it "returns the map id" do
          result.should_not be_nil
          map = SequencescapeModel::Map[:id => result]
          map.asset_size.should == asset_size
          map.description.should == location
        end
      end

      context "with an unknown map location" do
        let(:location) { "Z45" }

        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::UnknownLocation)
        end
      end
    end


    context "when getting an asset size" do
      let(:result) { wrapper.asset_size(asset_id) }

      context "with a known asset id" do
        let(:size) { 96 }
        let(:asset_id) { SequencescapeModel::Asset.insert(:size => size) }

        it "returns the size of the asset" do
          result.should == size
        end
      end

      context "with an unknown asset id" do
        let(:asset_id) { 15464 }

        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end


    context "when getting a tag id" do
      let(:result) { wrapper.tag_id(sample_id) }

      context "with a known sample id" do
        let(:sample_id) { 1 }
        before { SequencescapeModel::SampleMetadata.insert(:sample_id => sample_id, :sample_type => sample_type) }

        context "with DNA sample" do
          let(:sample_type) { "DNA" }

          it "returns the tag id" do
            result.should == -100
          end
        end

        context "with RNA sample" do
          let(:sample_type) { "RNA" }

          it "returns the tag id" do
            result.should == -101
          end
        end
      end

      context "with an unknown sample id" do
        let(:sample_id) { 146484 }

        it "returns the default tag id" do
          result.should == -1
        end
      end
    end


    context "when getting a study id" do
      let(:result) { wrapper.study_id(sample_id) }

      context "with a known sample id" do
        let(:sample_id) { 1 }
        let(:study_id) { 2 }
        before { SequencescapeModel::StudySample.insert(:sample_id => sample_id, :study_id => study_id) }

        it "returns a study id" do
          result.should == study_id
        end
      end

      context "with an unknown sample id" do
        let(:sample_id) { 4654 }

        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::StudyNotFound)
        end
      end
    end


    context "when getting an asset id by uuid" do
      let(:uuid) { "11111111-2222-3333-4444-555555555555" }
      let(:result) { wrapper.asset_id_by_uuid(uuid) }

      context "with a known uuid" do
        let(:resource_id) { 10 }
        before { SequencescapeModel::Uuid.insert(:resource_type => "Plate", :resource_id => resource_id, :external_id => uuid) }

        it "returns the asset id" do
          result.should == resource_id
        end
      end

      context "with an unknown uuid" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end


    context "when getting the well id by location" do
      let(:result) { wrapper.well_id_by_location(container_id, location) }

      context "with a known asset" do
        let(:container_id) { SequencescapeModel::Asset.insert(:size => 96) }
        let(:well_id) { SequencescapeModel::Asset.insert(:sti_type => settings["well_type"], :map_id => 1) }
        before { SequencescapeModel::ContainerAssociation.insert(:container_id => container_id, :content_id => well_id) }

        context "with a known location" do
          let(:location) { "A1" }

          it "returns the well id" do
            result.should == well_id
          end
        end

        context "with an unknown location" do
          let(:location) { "Z85" }

          it "raises an error" do
            expect do
              result
            end.to raise_error(SequencescapeWrapper::UnknownLocation)
          end
        end
      end

      context "with an unknown asset and a known location" do
        let(:location) { "A1" }
        let(:container_id) { 6464 }

        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end
  end
end
