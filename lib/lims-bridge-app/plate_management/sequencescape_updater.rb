require 'sequel'
require 'facets'

module Lims::BridgeApp
  module PlateManagement
    module SequencescapeUpdater

      # Exception raised after an unsuccessful lookup for a plate 
      # in Sequencescape database.
      PlateNotFoundInSequencescape = Class.new(StandardError)
      UnknownSample = Class.new(StandardError)
      UnknownLocation = Class.new(StandardError)
      InvalidBarcode = Class.new(StandardError)
      TransferRequestNotFound = Class.new(StandardError)

      Pattern = [8, 4, 4, 4, 12]
      UuidWithoutDashes = /#{Pattern.map { |n| "(\\w{#{n}})"}.join}/i

      # Ensure that all the requests for a message are made in a
      # transaction.
      def call
        db.transaction do
          _call_in_transaction
        end
      end

      # Create a plate in Sequencescape database.
      # The following tables are updated:
      # - Assets (the plate is saved with a Unassigned plate purpose)
      # - Assets (each well of the plate are saved with the right map_id)
      # - Uuids (the external id is S2 uuid)
      # - Container_associations (to link each well to the plate in Assets)
      # If the transaction fails, it raises a Sequel::Rollback exception and 
      # the transaction rollbacks.
      # @param [Lims::Core::Laboratory::Plate] plate
      # @param [String] plate uuid
      # @param [Time] date
      # @param [Hash] sample uuids
      def create_plate_in_sequencescape(plate, plate_uuid, date, sample_uuids)
        asset_size = plate.number_of_rows * plate.number_of_columns
        sti_type = plate.is_a?(Lims::LaboratoryApp::Laboratory::Gel) ? settings["gel_type"] : settings["plate_type"]

        # Save plate and plate uuid
        plate_id = db[:assets].insert(
          :sti_type => sti_type,
          :plate_purpose_id => settings["unassigned_plate_purpose_id"],
          :size => asset_size,
          :created_at => date,
          :updated_at => date
        ) 

        db[:uuids].insert(
          :resource_type => settings["asset_type"],
          :resource_id => plate_id,
          :external_id => plate_uuid
        ) 

        set_plate_location(plate_id)

        # Save wells and set the associations with the plate
        plate.keys.each do |location|
          map_id = db[:maps].select(:id).where(
            :description => location, 
            :asset_size => asset_size
          ).first[:id]

          well_id = db[:assets].insert(
            :sti_type => settings["well_type"], 
            :map_id => map_id,
            :created_at => date,
            :updated_at => date
          ) 

          db[:container_associations].insert(
            :container_id => plate_id, 
            :content_id => well_id
          ) 

          # Save the volume contained in the well ie the solvent quantity in S2 
          aliquot = plate[location].find { |aliquot| aliquot.type == "solvent" }
          volume = aliquot.quantity if aliquot
          set_well_volume_and_concentration(well_id, volume, nil, date) if volume

          # Save well aliquots
          if sample_uuids.has_key?(location)
            sample_uuids[location].each do |sample_uuid|
              sample_resource_uuid = db[:uuids].select(:resource_id).where(
                :resource_type => settings["sample_type"], 
                :external_id => sample_uuid
              ).first

              raise UnknownSample, "The sample #{sample_uuid} cannot be found in Sequencescape" unless sample_resource_uuid
              sample_id = sample_resource_uuid[:resource_id]

              tag_id = get_tag_id(sample_id)
              study_id = study_id(sample_id)
              create_asset_request!(well_id, study_id, date)

              db[:aliquots].insert(
                :receptacle_id => well_id, 
                :study_id => study_id,
                :sample_id => sample_id,
                :created_at => date,
                :updated_at => date,
                :tag_id => tag_id
              )
            end
          end 
        end
      end

      # @param [Integer] plate_id
      def set_plate_location(plate_id)
        location = db[:locations].where(:name => settings["plate_location"]).first
        raise UnknownLocation, "The location #{settings["plate_location"]} cannot be found in Sequencescape" unless location

        location_id = location[:id]
        db[:location_associations].insert(:locatable_id => plate_id, :location_id => location_id)
      end

      # @param [Integer] well_id
      # @param [Integer] study_id
      # @param [Time] date
      # Add a row in request unless it already exists for the well
      def create_asset_request!(well_id, study_id, date)
        request = db[:requests].where({
          :asset_id => well_id,
          :state => settings["create_asset_request_state"],
          :request_type_id => settings["create_asset_request_type_id"],
          :initial_study_id => study_id
        }).first

        unless request
          db[:requests].insert({
            :asset_id => well_id,
            :initial_study_id => study_id,
            :sti_type => settings["create_asset_request_sti_type"],
            :state => settings["create_asset_request_state"],
            :request_type_id => settings["create_asset_request_type_id"],
            :created_at => date,
            :updated_at => date 
          })
        end
      end

      # @param [Integer] source_well_id
      # @param [Integer] target_well_id
      # @param [Time] date
      def create_transfer_request!(source_well_id, target_well_id, date)
        db[:requests].insert({
          :created_at => date,
          :updated_at => date,
          :state => settings["transfer_request_state"],
          :request_type_id => settings["transfer_request_type_id"],
          :asset_id => source_well_id,
          :target_asset_id => target_well_id,
          :sti_type => settings["transfer_request_sti_type"]
        })
      end

      # @param [Integer] sample_id
      # @return [Integer]
      def study_id(sample_id)
        study = db[:study_samples].where(:sample_id => sample_id).order(:created_at).first 
        study[:study_id]
      end

      # Returns a the tag_id based on the type of the sample
      def get_tag_id(sample_id)
        tag_id = -1

        sample_type = db[:sample_metadata].select(:sample_type).where(
          :sample_id => sample_id).first

        if sample_type
          sample_type_value = sample_type[:sample_type]

          if sample_type_value.match(/\bDNA\b/)
            tag_id = -100
          elsif sample_type_value.match(/\bRNA\b/)
            tag_id = -101
          end
        end
        tag_id
      end
      private :get_tag_id

      # Update plate purpose in Sequencescape.
      # If the plate_uuid is not found in the database,
      # it means the order message has been received before 
      # the plate message. A PlateNotFoundInSequencescape exception 
      # is raised in that case. Otherwise, the plate is updated 
      # with the right plate_purpose_id for a stock plate.
      # @param [String] plate uuid
      # @param [Time] date 
      # @param [Integer] plate_purpose_id
      def update_plate_purpose_in_sequencescape(plate_uuid, date, plate_purpose_id)
        plate_id = plate_id_by_uuid(plate_uuid)
        db[:assets].where(:id => plate_id).update(
          :plate_purpose_id => plate_purpose_id,
          :updated_at => date
        ) 
      end

      # @param [String] uuid
      # @return [Integer]
      def plate_id_by_uuid(uuid)
        plate_uuid_data = db[:uuids].select(:resource_id).where(
          :external_id => uuid
        ).first

        raise PlateNotFoundInSequencescape, "The plate #{uuid} cannot be found in Sequencescape" unless plate_uuid_data
        plate_uuid_data[:resource_id]
      end

      def set_asset_link(asset_link_set)
        db[:asset_links].multi_insert(asset_link_set)
      end

      # @param [Integer] plate_id
      # @param [String] location
      # @return [Integer]
      def well_id_by_location(plate_id, location)
        map_id = get_map_id(location, plate_id)
        db[:assets].select(:assets__id).join(
          :container_associations, :content_id => :assets__id
        ).where({
          :container_id => plate_id,
          :sti_type => settings["well_type"],
          :map_id => map_id
        }).first[:id]
      end

      # @param [Integer] plate_id
      # @return [Hash]
      # @example {"A1" => 1548, "A2" => 1549...}
      def location_wells(plate_id)
        db[:container_associations].select(
          :assets__id, :maps__description
        ).join(
          :assets, :id => :content_id
        ).join(
          :maps, :id => :map_id
        ).where(:container_id => plate_id).all.inject({}) do |m,e|
          m.merge({e[:description] => e[:id]})
        end
      end

      # Move wells from a plate to a plate
      # @param [Lims::Core::Laboratory::Plate] plate
      # @param [String] plate uuid
      # @param [Hash] sample uuids
      def move_wells_in_sequencescape(move, date)
        source_plate_id = plate_id_by_uuid(move["source_uuid"])
        target_plate_id = plate_id_by_uuid(move["target_uuid"])
        source_location = move["source_location"]
        target_location = move["target_location"]
        source_map_id = get_map_id(source_location, source_plate_id)
        target_map_id = get_map_id(target_location, target_plate_id)

        well_id_for = lambda do |container_id, map_id|
          db[:assets].select(:assets__id).join(:container_associations, :content_id => :assets__id).where({
            :container_id => container_id,
            :map_id => map_id
          }).first[:id]
        end

        source_well_id = well_id_for.call(source_plate_id, source_map_id)
        target_well_id = well_id_for.call(target_plate_id, target_map_id)

        # Associate the well in the source location to the target tube rack
        # We delete the couple (source_plate_id, source_well_id) from the table
        # container_associations first as there is a unique constraint on content_id column.
        # Then we add the couple (target_plate_id, source_well_id).
        # Finally, we update the location of the well.
        db[:container_associations].where({
          :container_id => source_plate_id,
          :content_id => source_well_id
        }).delete

        db[:container_associations].insert(
          :container_id => target_plate_id,
          :content_id => source_well_id
        )

        db[:assets].where(:id => source_well_id).update({
          :map_id => target_map_id,
          :updated_at => date
        })

        # We attach then the old well of the target tube rack to the source tube rack
        # We delete the association between the old well and the target tube rack
        # And link that old empty well to the source tube rack
        # This well should normally be empty (no aliquots attached to it)
        # We update the location of the well finally.
        db[:container_associations].where({
          :container_id => target_plate_id,
          :content_id => target_well_id
        }).delete

        db[:container_associations].insert(
          :container_id => source_plate_id,
          :content_id => target_well_id
        )

        db[:assets].where(:id => target_well_id).update({
          :map_id => source_map_id,
          :updated_at => date
        })
      end

      # @param [String] the location string in the plate. For example: "A1"
      # @param [String] plate uuid
      # @return [String]
      def get_map_id(location, plate_id)
        map_id_data = db[:maps].select(:id).where({
          :description => location,
          :asset_size => db[:assets].select(:size).where(:id => plate_id)
        }).first

        raise UnknownLocation, "The location '#{location}' cannot be found in Sequencescape" unless map_id_data
        map_id_data[:id]
      end

      # Update the aliquots of a plate after a plate transfer
      # @param [Lims::Core::Laboratory::Plate] plate
      # @param [String] plate uuid
      # @param [Hash] sample uuids
      def update_aliquots_in_sequencescape(plate, plate_uuid, date, sample_uuids)
        plate_id = plate_id_by_uuid(plate_uuid)

        # wells is a hash associating a location to a well id
        wells = location_wells(plate_id) 

        # We save the plate wells data from the transfer
        plate.keys.each do |location|
          receptacle_id = wells[location]

          # Save aliquots
          if sample_uuids.has_key?(location)
            sample_uuids[location].each do |sample_uuid|
              sample_resource_uuid = db[:uuids].select(:resource_id).where(
                :resource_type => settings["sample_type"],
                :external_id => sample_uuid
              ).first

              raise UnknownSample, "The sample #{sample_uuid} cannot be found in Sequencescape" unless sample_resource_uuid
              sample_id = sample_resource_uuid[:resource_id]
              tag_id = get_tag_id(sample_id)
              study_id = study_id(sample_id)

              aliquot = db[:aliquots].where({
                :receptacle_id => receptacle_id, 
                :sample_id => sample_id, 
                :tag_id => tag_id
              }).first 

              # The aliquot is added only if it doesn't exist yet
              unless aliquot
                create_asset_request!(receptacle_id, study_id, date) 

                db[:aliquots].insert(
                  :receptacle_id => receptacle_id,
                  :sample_id => sample_id,
                  :study_id => study_id,
                  :created_at => date,
                  :updated_at => date,
                  :tag_id => tag_id
                )
              end
            end

            # Update or create well_attribute with volume and concentration information
            plate_solvent = plate[location].find { |aliquot| aliquot.type == "solvent" }
            plate_aliquot = plate[location].find { |aliquot| aliquot.type != "solvent" }            
            volume = plate_solvent.quantity if plate_solvent
            concentration = plate_aliquot.out_of_bounds[settings["out_of_bounds_concentration_key"]] if plate_aliquot
            set_well_volume_and_concentration(receptacle_id, volume, concentration, date) if volume || concentration

            # If we have a value for the concentration, it means we had received a working
            # dilution plate. We need then to update the concentration of the stock plate' wells
            # involved in the transfer to the working dilution plate.
            if concentration
              transfer_request = db[:requests].where({
                :target_asset_id => receptacle_id,
                :state => settings["transfer_request_state"],
                :request_type_id => settings["transfer_request_type_id"],
                :sti_type => settings["transfer_request_sti_type"]
              }).first

              raise TransferRequestNotFound, "The transfer request cannot be found in 'requests' table for the target_asset_id: #{receptacle_id}." unless transfer_request 
              source_well_id = transfer_request[:asset_id]

              source_concentration = concentration * settings["stock_plate_concentration_multiplier"]
              set_well_volume_and_concentration(source_well_id, nil, source_concentration, date)
            end
          end
        end
      end

      # @param [GelImage] gel_image
      # The score is updated in the original stock plate from which
      # a transfer has been done to a working dilution plate and then 
      # to a gel plate.
      def update_gel_scores(gel_image)
        unless gel_image.scores.empty?
          gel_id = plate_id_by_uuid(gel_image.gel_uuid)
          gel_image.scores.each do |location, score|
            well_id = well_id_by_location(gel_id, location)

            stock_well = db[:requests].from_self(:alias => :requests_stock_wd).join(
              :requests, :asset_id => :requests_stock_wd__target_asset_id
            ).select(:requests_stock_wd__asset_id).where(
              :requests__target_asset_id => well_id
            ).first

            next unless stock_well
            stock_well_id = stock_well[:asset_id]

            db[:well_attributes].where(:well_id => stock_well_id).update(
              :gel_pass => settings["gel_image_s2_scores_to_sequencescape_scores"][score] 
            )
          end
        end
      end

      # @param [Integer] well_id
      # @paran [Integer] volume
      # @paran [Float] concentration
      # @param [Time] date
      def set_well_volume_and_concentration(well_id, volume, concentration, date)
        well_attribute = db[:well_attributes].where(:well_id => well_id).first

        if well_attribute && (well_attribute[:current_volume] != volume || well_attribute[:concentration] != concentration)
          db[:well_attributes].where(:well_id => well_id).update({}.tap { |updates|
            updates[:concentration] = concentration if concentration
            updates[:current_volume] = volume if volume
            updates[:updated_at] = date
          })

        elsif well_attribute.nil?
          db[:well_attributes].insert(
            :well_id => well_id,
            :concentration => concentration,
            :current_volume => volume,
            :created_at => date,
            :updated_at => date
          )
        end       
      end

      # @param [String] plate_uuid
      # Delete the plate and all its references (wells, aliquots...)
      def delete_plate(plate_uuid)
        plate_id = plate_id_by_uuid(plate_uuid)
        well_ids = db[:container_associations].where(:container_id => plate_id).all.inject([]) do |m,e|
          m << e[:content_id]
        end

        db[:container_associations].where(:container_id => plate_id, :content_id => well_ids).delete
        db[:assets].where(:id => (well_ids + [plate_id])).delete
        db[:uuids].where(:external_id => plate_uuid).delete
        db[:aliquots].where(:receptacle_id => well_ids).delete
      end

      # @param [Hash] aliquot_locations
      # @example: {plate_uuid => [:A1, :B4]}
      # Delete all the aliquots in the location specified
      # in aliquot_locations.
      def delete_aliquots_in_sequencescape(aliquot_locations)
        aliquot_locations.each do |plate_uuid, locations|
          plate_id = plate_id_by_uuid(plate_uuid) 
          well_ids = db[:container_associations].select(
            :assets__id 
          ).join(
            :assets, 
            :id => :content_id
          ).join(
            :maps, 
            :id => :map_id
          ).where(:container_id => plate_id, :description => locations.map { |l| l.to_s }).all.inject([]) do |m,e|
            m << e[:id]
          end

          db[:aliquots].where(:receptacle_id => well_ids).delete
        end
      end

      # @param [Lims::LaboratoryApp::Labels::Labellable] labellable
      # @param [Time] date
      def set_barcode_to_a_plate(labellable, date)
        plate_uuid = labellable.name
        plate_uuid = Regexp.last_match[1..5].join("-") if plate_uuid =~ UuidWithoutDashes

        plate_id = plate_id_by_uuid(plate_uuid)
        barcode = sanger_barcode(labellable)
        prefix = barcode[:prefix]

        unless settings["barcode_prefixes"].keys.map { |p| p.downcase }.include?(prefix.downcase)
          raise InvalidBarcode, "#{prefix} is not a valid barcode prefix"
        end

        barcode_prefix_id = barcode_prefix_id(prefix)

        plate_name = "#{settings["barcode_prefixes"][prefix]} #{barcode[:number]}"

        db[:assets].where(:id => plate_id).update({
          :name => plate_name,
          :barcode => barcode[:number], 
          :barcode_prefix_id => barcode_prefix_id,
          :updated_at => date
        })
      end

      # @param [String] prefix
      # @return [Integer]
      # Return the prefix id. Create the prefix if
      # it does not exist yet.
      def barcode_prefix_id(prefix)
        barcode_prefix = db[:barcode_prefixes].where(:prefix => prefix).first
        return barcode_prefix[:id] if barcode_prefix

        db[:barcode_prefixes].insert(:prefix => prefix)
        return barcode_prefix_id(prefix)
      end
      private :barcode_prefix_id

      # @param [Lims::LaboratoryApp::Labels::Labellable] labellable
      # @return [Hash]
      # Return the first sanger barcode found in the labellable
      # The preceeding zeroes from the barcode are stripped for sequencescape.
      def sanger_barcode(labellable)
        labellable.each do |position, label|
          if label.type == settings["sanger_barcode_type"]
            label.value.match(/^(\w{2})([0-9]*)\w$/)
            prefix = $1
            number = $2.to_i.to_s
            return {:prefix => prefix, :number => number} 
          end
        end
      end
      private :sanger_barcode

      # @param [String] plate_uuid
      # @param [Hash] location_samples
      # @param [Hash] swaps
      # @param [Time] date
      def swap_samples(plate_uuid, location_samples, swaps, date)
        plate_id = plate_id_by_uuid(plate_uuid)
        location_wells = location_wells(plate_id)

        location_wells.each do |location, well_id|
          sample_uuids = location_samples[location]
          next unless sample_uuids

          sample_uuids.each do |sample_uuid|
            old_sample_uuid = swaps.inverse[sample_uuid]
            next unless old_sample_uuid

            sample_resource_uuid = db[:uuids].where(:resource_type => settings["sample_type"], :external_id => sample_uuid).first 
            raise UnknownSample, "The sample #{sample_uuid} cannot be found in Sequencescape" unless sample_resource_uuid
            sample_id = sample_resource_uuid[:resource_id]

            old_sample_resource_uuid = db[:uuids].where(:resource_type => settings["sample_type"], :external_id => old_sample_uuid).first 
            raise UnknownSample, "The sample #{old_sample_uuid} cannot be found in Sequencescape" unless old_sample_resource_uuid
            old_sample_id = old_sample_resource_uuid[:resource_id]

            db[:aliquots].where(
              :receptacle_id => well_id, :sample_id => old_sample_id
            ).update(:sample_id => sample_id, :updated_at => date) 
          end
        end
      end
    end
  end 
end
