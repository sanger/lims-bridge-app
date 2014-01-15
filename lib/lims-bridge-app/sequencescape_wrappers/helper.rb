module Lims::BridgeApp
  class SequencescapeWrapper
    UnknownLocation = Class.new(StandardError)

    module Helper
      # @param [String] resource_type
      # @param [Integer] resource_id
      # @param [String] external_id
      # @return [Integer] uuid internal id
      def create_uuid(resource_type, resource_id, external_id)
        SequencescapeModel::Uuids.new.tap do |uuid|
          uuid.resource_type = resource_type
          uuid.resource_id = resource_id
          uuid.external_id = external_id
        end.save
      end

      # @param [Integer] asset_id
      # @return [Integer] location associations internal id
      # @raise [UnknownLocation]
      def create_location(asset_id)
        location_model = SequencescapeModel::Locations[:name => settings["plate_location"]]
        raise UnknownLocation, "The location #{settings["plate_location"]} cannot be found in Sequencescape" unless location_model

        SequencescapeModel::LocationAssociations.new.tap do |la|
          la.locatable_id = asset_id
          la.location_id = location_model.id
        end.save
      end

      # @param [String] location
      # @param [Integer] asset_size
      # @return [Integer] map id
      def map_id(location, asset_size)
        SequencescapeModel::Maps[:description => location, :asset_size => asset_size].id
      end

      # @param [Integer] sample_id
      # @return [Integer] tag id
      def tag_id(sample_id)
        tag_id = -1
        sample_metadata_model = SequencescapeModel::SampleMetadata[:sample_id => sample_id]

        if sample_metadata_model
          case sample_metadata_model.sample_type
          when /\bDNA\b/ then tag_id = -100
          when /\bRNA\b/ then tag_id = -101
          end
        end

        tag_id
      end

      # @param [Integer] sample_id
      # @return [Integer] study id
      def study_id(sample_id)
        SequencescapeModel::StudySamples[:sample_id => sample_id].order(:created_at).study_id
      end
    end
  end
end
