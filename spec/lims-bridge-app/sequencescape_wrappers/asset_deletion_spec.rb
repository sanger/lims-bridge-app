require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    context "when deleting an asset" do
      let(:asset_uuid) { uuid [1,2,3,4,5] }
      let(:result) { wrapper.delete_asset(asset_uuid) }

      context "with a valid asset uuid" do
        include_context "create an asset"

        it_behaves_like "changing table", :container_associations, -96
        it_behaves_like "changing table", :assets, -97
        it_behaves_like "changing table", :uuids, -1
        it_behaves_like "changing table", :aliquots, -4
      end

      context "with an unknown asset uuid" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end
  end
end
