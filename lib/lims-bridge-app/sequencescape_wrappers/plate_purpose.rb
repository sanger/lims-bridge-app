module Lims::BridgeApp
  class SequencescapeWrapper
    module PlatePurpose
      # @param [String] asset_uuid
      # @param [Integer] plate_purpose_id
      # @raise [AssetNotFound] 
      def update_plate_purpose(asset_uuid, plate_purpose_id)  
        asset_id = asset_id_by_uuid(asset_uuid)
        SequencescapeModel::Asset[:id => asset_id].tap do |asset|
          asset.plate_purpose_id = plate_purpose_id
          asset.updated_at = date
        end.save
      end
    end
  end
end
