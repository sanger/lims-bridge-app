module Lims::BridgeApp
  class SequencescapeWrapper
    module Transfer
      # @param [Integer] ancestor_id
      # @param [Integer] descendant_id
      # Create an asset link if it doesn't exist already
      def create_asset_link(ancestor_id, descendant_id)
        return if SequencescapeModel::AssetLink[:ancestor_id => ancestor_id, :descendant_id => descendant_id]
        SequencescapeModel::AssetLink.new.tap do |al|
          al.ancestor_id = ancestor_id 
          al.descendant_id = descendant_id 
          al.direct = 1
          al.count = 1
          al.created_at = date
          al.updated_at = date
        end.save
      end

      # @param [Integer] source_well_id
      # @param [Integer] target_well_id
      def create_transfer_request(source_well_id, target_well_id)
        SequencescapeModel::Request.new.tap do |r|
          r.created_at = date
          r.updated_at = date
          r.state = settings["transfer_request_state"]
          r.request_type_id = settings["transfer_request_type_id"]
          r.asset_id = source_well_id
          r.target_asset_id = target_well_id
          r.sti_type = settings["transfer_request_sti_type"]
        end.save
      end

      # @param [String] source_uuid
      # @param [String] source_location
      # @param [String] target_uuid
      # @param [String] target_location
      # @raise [AssetNotFound,UnknownLocation]
      # Moving well is done by swapping the source well with the target well,
      # as the target_well should be empty.
      def move_well(source_uuid, source_location, target_uuid, target_location)
        source_id, target_id = asset_id_by_uuid(source_uuid), asset_id_by_uuid(target_uuid)  
        source_size, target_size = asset_size(source_id), asset_size(target_id)
        source_map_id, target_map_id = map_id(source_size, source_location), map_id(target_size, target_location)
        source_well_id = well_id_by_location(source_id, source_location)
        target_well_id = well_id_by_location(target_id, target_location)

        # Associate the well in the source location to the target location. 
        # We delete the couple (source_plate_id, source_well_id) from the table
        # container_associations first as there is a unique constraint on content_id column.
        # Then we add the couple (target_plate_id, source_well_id).
        # Finally, we update the location of the well.
        SequencescapeModel::ContainerAssociation[:container_id => source_id, :content_id => source_well_id].delete
        SequencescapeModel::ContainerAssociation.new.tap do |ca|
          ca.container_id = target_id
          ca.content_id = source_well_id
        end.save

        SequencescapeModel::Asset[:id => source_well_id].tap do |a|
          a.map_id = target_map_id
          a.updated_at = date
        end.save

        # We attach then the old well of the target tube rack to the source tube rack
        # We delete the association between the old well and the target tube rack
        # And link that old empty well to the source tube rack
        # This well should normally be empty (no aliquots attached to it)
        # We update the location of the well finally.
        SequencescapeModel::ContainerAssociation[:container_id => target_id, :content_id => target_well_id].delete
        SequencescapeModel::ContainerAssociation.new.tap do |ca|
          ca.container_id = source_id
          ca.content_id = target_well_id
        end.save

        SequencescapeModel::Asset[:id => target_well_id].tap do |a|
          a.map_id = source_map_id
          a.updated_at = date
        end.save
      end

      # @param [String] asset_uuid
      # @param [Hash] asset_sample_uuids
      # @param [Hash] swaps
      def swap_samples(asset_uuid, asset_sample_uuids, swaps)
        asset_id = asset_id_by_uuid(asset_uuid)
        location_well_id(asset_id).each do |location, well_id|
          sample_uuids = asset_sample_uuids[location]
          next unless sample_uuids

          sample_uuids.each do |sample_uuid|
            old_sample_uuid = swaps.inverse[sample_uuid]
            next unless old_sample_uuid

            sample_id = asset_id_by_uuid(sample_uuid)
            old_sample_id = asset_id_by_uuid(old_sample_uuid)

            SequencescapeModel::Aliquot[:receptacle_id => well_id, :sample_id => old_sample_id].tap do |a|
              a.sample_id = sample_id
              a.updated_at = date
            end.save
          end
        end
      end
    end
  end
end
