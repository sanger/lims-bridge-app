require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    context "when updating the plate purpose of a known asset" do
      let(:asset_uuid) { uuid [1,2,3,4,5] }
      let(:plate_purpose_id) { 12 }
      let(:result) { wrapper.update_plate_purpose(asset_uuid, plate_purpose_id) }

      context "with a known asset" do
        include_context "create an asset"
        before { result }

        it "sets the plate purpose" do
          asset_id = wrapper.asset_id_by_uuid(asset_uuid)
          SequencescapeModel::Asset[:id => asset_id].tap do |asset|
            asset.plate_purpose_id.should == plate_purpose_id
            asset.updated_at.to_s.should == date
          end
        end
      end

      context "with an unknown asset" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end
  end
end
