module Lims::BridgeApp
  class SequencescapeWrapper
    UnknownLocation = Class.new(StandardError)
    StudyNotFound = Class.new(StandardError)
    AssetNotFound = Class.new(StandardError)

    module Helper
      # @param [String] resource_type
      # @param [Integer] resource_id
      # @param [String] external_id
      # @return [SequencescapeModel::Uuid]
      def create_uuid(resource_type, resource_id, external_id)
        SequencescapeModel::Uuid.new.tap do |uuid|
          uuid.resource_type = resource_type
          uuid.resource_id = resource_id
          uuid.external_id = external_id
        end.save
      end

      # @param [Integer] asset_id
      # @return [Integer] location associations internal id
      # @raise [UnknownLocation]
      def create_location_association(asset_id)
        location_model = SequencescapeModel::Location[:name => settings["plate_location"]]
        raise UnknownLocation, "The location #{settings["plate_location"]} cannot be found in Sequencescape" unless location_model

        SequencescapeModel::LocationAssociation.new.tap do |la|
          la.locatable_id = asset_id
          la.location_id = location_model.id
        end.save
      end

      # @param [Integer] asset_size
      # @param [String] location
      # @return [Integer] map id
      def map_id(asset_size, location)
        map_model = SequencescapeModel::Map[:description => location, :asset_size => asset_size]              
        raise UnknownLocation, "The location #{location} cannot be found" unless map_model
        map_model.id
      end

      # @param [Integer] asset_id
      # @return [Integer] asset size
      # @raise [AssetNotFound]
      def asset_size(asset_id)
        asset = SequencescapeModel::Asset[:id => asset_id]
        raise AssetNotFound, "The asset #{asset_id} cannot be found" unless asset 
        asset.size
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
      # @raise [StudyNotFound]
      def study_id(sample_id)
        study_samples_model = SequencescapeModel::StudySample.where(:sample_id => sample_id).order(:created_at).first
        raise StudyNotFound, "Cannot find study for the sample id #{sample_id}" unless study_samples_model 
        study_samples_model.study_id
      end

      # @param [String] uuid
      # @return [Integer] asset id
      # @raise [AssetNotFound]
      def asset_id_by_uuid(uuid)
        uuid_model = SequencescapeModel::Uuid[:external_id => uuid]
        raise AssetNotFound, "The resource #{uuid} cannot be found in Sequencescape" unless uuid_model
        uuid_model.resource_id
      end

      # @param [Integer] container_id
      # @param [String] location
      # @return [Integer] well id
      def well_id_by_location(container_id, location)
        asset = SequencescapeModel::Asset[:id => container_id]
        raise AssetNotFound, "The asset #{container_id} cannot be found" unless asset
        asset_size = asset.size

        map_id = map_id(asset_size, location)
        SequencescapeModel::Asset.select(:assets__id).join(
          :container_associations, :content_id => :assets__id
        ).where(:container_id => container_id, :sti_type => settings["well_type"], :map_id => map_id).first.id
      end
    end
  end
end
