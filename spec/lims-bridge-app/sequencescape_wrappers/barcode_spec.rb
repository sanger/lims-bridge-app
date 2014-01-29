require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'
require 'lims-laboratory-app/labels/labellable'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    let(:asset_uuid) { uuid [1,2,3,4,5] }
    let(:labellable) {
      Lims::LaboratoryApp::Labels::Labellable.new(:name => asset_uuid, :type => "resource").tap { |l|
        l["front"] = Lims::LaboratoryApp::Labels::Labellable::Label.new({
          :type => settings["sanger_barcode_type"],
          :value => sanger_barcode_value 
        })
      }
    }


    context "when getting the barcode prefix id" do
      let(:sanger_barcode_value) { "WD123456A" }
      let(:result) { wrapper.send(:barcode_prefix_id, "WD") }

      context "with a new barcode prefix" do
        it_behaves_like "changing table", :barcode_prefixes, 1
        it "returns the barcode prefix id" do
          result.should_not be_nil
        end
      end

      context "with an existing barcode prefix" do
        before { SequencescapeModel::BarcodePrefixe.insert(:prefix => "WD") }
        it_behaves_like "changing table", :barcode_prefixes, 0
        it "returns the barcode prefix id" do
          result.should_not be_nil
        end
      end
    end


    context "when extracting the sanger barcode" do
      let(:sanger_barcode_value) { "WD123456A" }

      it "returns the prefix and numbers associated to the sanger barcode in the labellable" do
        wrapper.send(:sanger_barcode, labellable).tap do |sb|
          sb.should be_a(Hash)
          sb[:prefix].should == "WD"
          sb[:number].should == "123456"
        end
      end
    end


    context "when barcode an asset" do
      let(:result) { wrapper.barcode_an_asset(labellable) }

      context "with a known asset and a valid barcode prefix" do
        include_context "create an asset" 
        let(:sanger_barcode_value) { "WD123456A" }
        let!(:barcode_prefix_id) { SequencescapeModel::BarcodePrefixe.insert(:prefix => "WD") }
        before { result }

        it "sets barcode informations on the asset" do
          asset_id = wrapper.asset_id_by_uuid(asset_uuid)
          SequencescapeModel::Asset[:id => asset_id].tap do |asset|
            asset.name.should == "Working dilution 123456"
            asset.barcode.should == "123456"
            asset.barcode_prefix_id = barcode_prefix_id
            asset.updated_at.to_s.should == date
          end
        end
      end

      context "with a known asset and an invalid barcode prefix" do
        include_context "create an asset"
        let(:sanger_barcode_value) { "ZZ123456A" }
        
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::InvalidBarcode)
        end
      end

      context "with an unknown barcoded asset" do
        let(:sanger_barcode_value) { "WD123456A" }
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end
  end
end
