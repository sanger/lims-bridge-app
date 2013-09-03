require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/laboratory/aliquot'
require 'lims-laboratory-app/organization/order'
require 'lims-laboratory-app/labels/labellable'
require 'lims-bridge-app/base_json_decoder'
require 'json'

module Lims::BridgeApp
  module PlateManagement
    # Json Decoder which decodes a S2 json message into a
    # Lims Core Resource.
    module JsonDecoder
      include BaseJsonDecoder

      module LabellableJsonDecoder
        def self.call(json, options)
          l_hash = json["labellable"]
          labellable = Lims::LaboratoryApp::Labels::Labellable.new({
            :name => l_hash["name"],
            :type => l_hash["type"]
          })
          l_hash["labels"].each do |position, label_info|
            label = Lims::LaboratoryApp::Labels::Labellable::Label.new({
              :type => label_info["type"],
              :value => label_info["value"]
            })
            labellable[position] = label
          end

          {:labellable => labellable, :date => options[:date]}
        end
      end


      module BulkCreateLabellableJsonDecoder
        def self.call(json, options)
          labellables = []
          json["bulk_create_labellable"]["labellables"].each do |labellable|
            labellables << LabellableJsonDecoder.call({"labellable" => labellable}, options)
          end
          {:labellables => labellables}
        end
      end


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
                plate[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new({
                  :quantity => aliquot["quantity"],
                  :type => aliquot["type"]
                })
              end
            end
          end

          {
            :plate => plate, 
            :uuid => plate_hash["uuid"], 
            :sample_uuids => sample_uuids(plate_hash["wells"]),
            :date => options[:date]
          }
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
              plate[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new({
                :quantity => aliquot["quantity"],
                :type => aliquot["type"]
              })
            end
          end

          {
            :plate => plate,
            :uuid => tuberack_hash["uuid"],
            :sample_uuids => sample_uuids(tuberack_hash["tubes"]),
            :date => options[:date]
          }
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

          {:order => order, :uuid => order_h["uuid"], :date => options[:date]}
        end
      end


      module PlateTransferJsonDecoder
        def self.call(json, options)
          transfer_h = json["plate_transfer"]
          PlateJsonDecoder.call(transfer_h["result"], options)         
        end
      end


      module TransferPlatesToPlatesJsonDecoder
        def self.call(json, options)
          plates = []
          json["transfer_plates_to_plates"]["result"]["targets"].each do |target|
            plates << case target.first
            when "plate" then PlateJsonDecoder.call(target, options) 
            when "tube_rack" then TubeRackJsonDecoder.call(target, options)
            end
          end

          {:plates => plates}
        end
      end


      module TubeRackTransferJsonDecoder
        def self.call(json, options)
          TubeRackJsonDecoder.call(json["tube_rack_transfer"]["result"], options) 
        end
      end


      module TubeRackMoveJsonDecoder
        def self.call(json, options)
          moves = json["tube_rack_move"]["moves"]

          {:moves => moves, :date => options[:date]}
        end
      end


      module SwapSamplesJsonDecoder
        def self.call(json, options)
          resources = [].tap do |r|
            json["swap_samples"]["result"].each do |resource|
              model = resource.keys.first
              decoder = case model
                        when "tube_rack" then TubeRackJsonDecoder
                        when "plate" then PlateJsonDecoder
                        end
              r << decoder.call(resource, options) if decoder 
            end
          end
          swaps = json["swap_samples"]["parameters"]

          {:resources => resources, :swaps => swaps, :date => options[:date]}
        end
      end
    end
  end
end
