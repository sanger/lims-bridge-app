module Lims::BridgeApp
  class SequencescapeWrapper
    InvalidContainer = Class.new(StandardError)
    UnknownSample = Class.new(StandardError)

    module AssetCreation
      # @param [Lims::LaboratoryApp::Laboratory::Container] container
      # @param [String] container_uuid
      # @param [Hash] sample_uuids
      # @return [Integer] asset internal id
      # @raise [InvalidContainer,UnknownSample]
      def create_asset(container, container_uuid, sample_uuids)
        asset_size = container.number_of_rows * container.number_of_columns
        sti_type = case container
                   when Lims::LaboratoryApp::Laboratory::Plate then settings["plate_type"]
                   when Lims::LaboratoryApp::Laboratory::Gel then settings["gel_type"]
                   else raise InvalidContainer, "The container #{container.class} is not supported yet"
                   end

        asset_id = SequenscapeModel::Assets.new.tap do |asset|
          asset.sti_type = sti_type
          asset.plate_purpose_id = settings["unassigned_plate_purpose_id"]
          asset.size = asset_size
          asset.created_at = date
          asset.updated_at = date
        end.save

        container.each do |location, receptacle|
          # Associate the well to its container
          well_id = create_well(asset_id, asset_size, location) 
          create_container_association(asset_id, well_id)

          # Add volume information to the well
          solvent = receptacle.find { |aliquot| aliquot.type == "solvent" }
          volume = solvent.quantity if solvent
          set_well_attributes(well_id, :volume => volume) if volume

          # Create aliquots for the well
          if sample_uuids.has_key?(location)
            well_sample_uuids = sample_uuids[location]
            create_aliquots(well_id, well_sample_uuids) 
          end
        end

        asset_id
      end

      private

      # @param [Integer] asset_id
      # @param [Integer] asset_size
      # @param [String] location
      # @return [Integer] well id
      def create_well(asset_id, asset_size, location)
        SequencescapeModel::Assets.new.tap do |well|
          well.sti_type = settings["well_type"]
          well.map_id = map_id(location, asset_size)
          well.created_at = date
          well.updated_at = date
        end.save
      end

      # @param [Integer] well_id
      # @param [Array] well_sample_uuids
      # @raise [UnknownSample]
      def create_aliquots(well_id, well_sample_uuids)
        well_sample_uuids.each do |sample_uuid|
          sample_uuid_model = SequencescapeModel::Uuids[:resource_type => settings["sample_type"], :external_id => sample_uuid]
          raise UnknownSample, "The sample #{sample_uuid} cannot be found in Sequencescape" unless sample_uuid_model

          sample_id = sample_uuid_model.resource_id
          study_id = study_id(sample_id)
          tag_id = tag_id(sample_id)
          create_asset_request(well_id, study_id) 

          SequencescapeModel::Aliquots.new.tap do |aliquot|
            aliquot.receptacle_id = well_id
            aliquot.study_id = study_id
            aliquot.sample_id = sample_id
            aliquot.tag_id = tag_id
            aliquot.created_at = date
            aliquot.updated_at = date
          end.save
        end
      end

      # @param [Integer] asset_id
      # @param [Integer] well_id
      # @return [Integer] container association id
      def create_container_association(asset_id, well_id)
        SequencescapeModel::ContainerAssociations.new.tap do |ca|
          ca.container_id = asset_id
          ca.content_id = well_id
        end.save
      end

      # @param [Integer] well_id
      # @param [Integer] study_id
      # @return [Integer] asset request id
      def create_asset_request(well_id, study_id)
        request = SequencescapeModel::Requests[{
          :asset_id => well_id,
          :state => settings["create_asset_request_state"],
          :request_type_id => settings["create_asset_request_type_id"],
          :initial_study_id => study_id
        }]

        unless request
          request = SequencescapeModel::Requests.new.tap do |new_request|
            new_request.asset_id = well_id
            new_request.initial_study_id = study_id
            new_request.sti_type = settings["create_asset_request_sti_type"]
            new_request.state = settings["create_asset_request_state"]
            new_request.request_type_id = settings["create_asset_request_type_id"]
            new_request.created_at = date
            new_request.updated_at = date
          end.save
        end

        request.id
      end

      # @param [Integer] well_id
      # @param [Hash] parameters
      # @return [Integer] well attribute id
      def set_well_attributes(well_id, parameters = {})
        well_attribute = SequencescapeModel::WellAttributes[:well_id => well_id]

        unless well_attribute
          return SequencescapeModel::WellAttributes.new.tap do |wa|
            wa.well_id = well_id
            wa.created_at = date
            wa.updated_at = date
            parameters.each do |key,value|
              wa.send(key, value) if wa.respond_to?(key)
            end
          end.save
        end
  
        to_update = false
        parameters.each do |key,value|
          to_update |= (well_attribute.send(key) != value) 
          well_attribute.send(key, value)
        end

        well_attribute.tap { |wa| wa.updated_at = date }.save
      end
    end
  end
end
