require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/laboratory/aliquot'
require 'lims-laboratory-app/organization/order'
require 'lims-bridge-app/base_json_decoder'
require 'json'

module Lims::BridgeApp
  module PlateCreator
    # Json Decoder which decodes a S2 json message into a
    # Lims Core Resource.
    module JsonDecoder
      include BaseJsonDecoder

      module PlateJsonDecoder
        # Create a Core Laboratory Plate from the json
        # @param [String] json
        # @return [Hash] hash
        # @example
        # {:plate => Lims::Core::Laboratory::Plate, 
        #  :uuid => "plate_uuid", 
        #  :sample_uuids => {"A1" => ["sample_uuid"]}}
        def self.call(json, options)
          plate_hash = json["plate"]
          plate = Lims::LaboratoryApp::Laboratory::Plate.new({:number_of_rows => plate_hash["number_of_rows"],
                                                              :number_of_columns => plate_hash["number_of_columns"]})   
          plate_hash["wells"].each do |location, aliquots|
            unless aliquots.empty?
              aliquots.each do |aliquot|
                plate[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new
              end
            end
          end

          {:plate => plate, 
           :uuid => plate_hash["uuid"], 
           :sample_uuids => sample_uuids(plate_hash["wells"])}
        end

        # Get the sample uuids in the plate
        # @param [Hash] wells
        # @return [Hash] sample uuids
        # @example
        # {"A1" => ["sample_uuid1", "sample_uuid2"]} 
        def self.sample_uuids(wells)
          {}.tap do |uuids|
            wells.each do |location, aliquots|
              unless aliquots.empty?
                aliquots.each do |aliquot|
                  uuids[location] ||= []
                  uuids[location] << aliquot["sample"]["uuid"]
                end
              end
            end
          end
        end
      end


      module TubeRackJsonDecoder
        # As a tuberack is seen as a plate in sequencescape,
        # we map below a tuberack to a s2 plate.
        # Basically, in a tuberack, a tube is mapped to a well,
        # the content of the tube is mapped to the content of a well.
        def self.call(json, options)
          tuberack_hash = json["tube_rack"]
          plate = Lims::LaboratoryApp::Laboratory::Plate.new({:number_of_rows => tuberack_hash["number_of_rows"],
                                                     :number_of_columns => tuberack_hash["number_of_columns"]})
          tuberack_hash["tubes"].each do |location, tube|
            tube["aliquots"].each do |aliquot|
              plate[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new
            end
          end

          {:plate => plate,
           :uuid => tuberack_hash["uuid"],
           :sample_uuids => sample_uuids(tuberack_hash["tubes"])}
        end

        # Get the sample uuids in the tuberack
        # The location returned is the location of the tube
        # with all its corresponding sample uuids.
        # @param [Hash] tubes
        # @return [Hash] sample uuids
        # @example
        # {"A1" => ["sample_uuid1", "sample_uuid2"]} 
        def self.sample_uuids(tubes)
          {}.tap do |uuids|
            tubes.each do |location, tube|
              tube["aliquots"].each do |aliquot|
                uuids[location] ||= []
                uuids[location] << aliquot["sample"]["uuid"] if aliquot["sample"]
              end
            end
          end
        end
      end


      module OrderJsonDecoder
        def self.call(json, options)
          order_h = json["order"]
          order = Lims::LaboratoryApp::Organization::Order.new
          order_h["items"].each do |role, settings|
            settings.each do |s|
              items = order.fetch(role) { |_| order[role] = [] }
              items << Lims::LaboratoryApp::Organization::Order::Item.new({
                :uuid => s["uuid"],
                :status => s["status"]
              })
            end
          end

          {:order => order, :uuid => order_h["uuid"]}
        end
      end


      module PlateTransferJsonDecoder
        def self.call(json, options)
          transfer_h = json["plate_transfer"]
          PlateJsonDecoder.call(transfer_h["result"])         
        end
      end


      module TransferPlatesToPlatesJsonDecoder
        def self.call(json, options)
          plates = []
          json["transfer_plates_to_plates"]["result"]["targets"].each do |plate|
            plates << PlateJsonDecoder.call(plate)
          end

          {:plates => plates}
        end
      end
    end
  end
end
