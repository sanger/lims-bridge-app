module Lims::BridgeApp
  class SequencescapeWrapper
    module AssetDeletion
      # @param [String] asset_uuid
      # @raise [AssetNotFound]
      def delete_asset(asset_uuid)
        asset_id = asset_id_by_uuid(asset_uuid)
        container_associations = SequencescapeModel::ContainerAssociation.where(:container_id => asset_id).all
        well_ids = container_associations.inject([]) { |m,e| m << e[:content_id] } 

        SequencescapeModel::ContainerAssociation.where(:container_id => asset_id, :content_id => well_ids).delete
        SequencescapeModel::Asset.where(:id => (well_ids + [asset_id])).delete
        SequencescapeModel::Uuid.where(:external_id => asset_uuid).delete
        SequencescapeModel::Aliquot.where(:receptacle_id => well_ids).delete
      end
    end
  end
end
