module Lims::BridgeApp
  class SequencescapeWrapper
    TransferRequestNotFound = Class.new(StandardError)

    module AliquotsUpdate
      # @param [Lims::LaboratoryApp::Laboratory::Container] asset
      # @param [String] asset_uuid
      # @param [Hash] sample_uuids
      # @raise [AssetNotFound,UnknownSample,TransferRequestNotFound]
      def update_aliquots(asset, asset_uuid, sample_uuids)
        asset_id = asset_id_by_uuid(asset_uuid)
        location_well_id = location_well_id(asset_id) 

        asset.each_with_index do |receptacle, location|
          well_id = location_well_id[location]
          if sample_uuids.has_key?(location)
            # Create new aliquots
            well_sample_uuids = sample_uuids[location]
            create_aliquots(well_id, well_sample_uuids) 

            # Set the volume and concentration information on the well
            solvent = receptacle.find { |aliquot| aliquot.type == "solvent" }
            aliquot = receptacle.find { |aliquot| aliquot.type != "solvent" && aliquot.out_of_bounds }
            volume = solvent.quantity if solvent
            concentration = aliquot.out.of_bounds[settings["out_of_bounds_concentration_key"]] if aliquot
            set_well_attributes(well_id, {:volume => volume, :concentration => concentration}) if volume || concentration

            # If we have a value for the concentration, it means we have received a working 
            # dilution plate. We need then to update the concentration of the associated stock 
            # plate wells, involved in the transfer to the working dilution plate.
            update_stock_plate_well_concentration(well_id, concentration) if concentration
          end
        end
      end

      # @param [Integer] working_dilution_well_id
      # @param [Float] concentration
      # @raise [TransferRequestNotFound]
      def update_stock_plate_well_concentration(working_dilution_well_id, concentration)
        transfer_request_stock_to_wd = SequencescapeModel::TransferRequest[{
          :target_asset_id => working_dilution_well_id,
          :state => settings["transfer_request_state"],
          :request_type_id => settings["transfer_request_type_id"],
          :sti_type => settings["transfer_request_sti_type"]
        }]

        unless transfer_request_stock_to_wd
          raise TransferRequestNotFound, "The transfer request cannot be found in 'requests' table for the target_asset_id: #{working_dilution_well_id}."
        end

        stock_well_id = transfer_request_stock_to_wd.asset_id
        source_concentration = concentration * settings["stock_plate_concentration_multiplier"]
        set_well_attributes(stock_well_id, :concentration => source_concentration)
      end

      # @param [Integer] asset_id
      # @return [Hash] location to well_id
      def location_well_id(asset_id)
        SequencescapeModel::ContainerAssociation.select(
          :assets__id, :maps__description
        ).join(
          :assets, :id => :content_id
        ).join(
          :maps, :id => :map_id
        ).where(:container_id => asset_id).all.inject({}) do |m,e|
          m.merge({e[:description] => e[:id]})
        end
      end
    end
  end
end

