require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/laboratory/gel'
require 'lims-laboratory-app/laboratory/aliquot'
require 'lims-laboratory-app/organization/order'
require 'lims-laboratory-app/labels/labellable'
require 'lims-quality-app/gel-image/gel_image'
require 'lims-bridge-app/base_json_decoder'
require 'json'

module Lims::BridgeApp
  module PlateManagement
    # Json Decoder which decodes a S2 json message into a
    # Lims Core Resource.
    module JsonDecoder
      include BaseJsonDecoder

      module GelImageJsonDecoder
        def self.call(json, options)
          gi_hash = json["gel_image"]
          gi = Lims::QualityApp::GelImage.new({
            :gel_uuid => gi_hash["gel_uuid"],
            :scores => gi_hash["scores"]
          })

          {:gel_image => gi, :date => options[:date]}
        end
      end


      module UpdateGelImageScoreJsonDecoder
        def self.call(json, options)
          gel_image = json["update_gel_image_score"]["result"]
          GelImageJsonDecoder.call(gel_image, options)
        end
      end


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


      module UpdateLabelJsonDecoder
        def self.call(json, options)
          LabellableJsonDecoder.call(json["update_label"]["result"], options)
        end
      end


      module BulkUpdateLabelJsonDecoder
        def self.call(json, options)
          labellables = []
          json["bulk_update_label"]["result"]["labellables"].each do |labellable|
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
                out_of_bounds = aliquot["out_of_bounds"] ? aliquot["out_of_bounds"] : {}
                plate[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new({
                  :quantity => aliquot["quantity"],
                  :type => aliquot["type"],
                  :out_of_bounds => out_of_bounds
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
                  uuids[location] << aliquot["sample"]["uuid"] if aliquot["sample"]
                end
              end
            end
          end
        end
      end


      module GelJsonDecoder
        def self.call(json, options)
          gel_hash = json["gel"]
          gel = Lims::LaboratoryApp::Laboratory::Gel.new({
            :number_of_rows => gel_hash["number_of_rows"],
            :number_of_columns => gel_hash["number_of_columns"]
          })
          gel_hash["windows"].each do |location, aliquots|
            unless aliquots.empty?
              aliquots.each do |aliquot|
                out_of_bounds = aliquot["out_of_bounds"] ? aliquot["out_of_bounds"] : {}
                gel[location] << Lims::LaboratoryApp::Laboratory::Aliquot.new({
                  :quantity => aliquot["quantity"],
                  :type => aliquot["type"],
                  :out_of_bounds => out_of_bounds
                })
              end
            end
          end

          {
            :plate => gel, 
            :uuid => gel_hash["uuid"], 
            :sample_uuids => PlateJsonDecoder.sample_uuids(gel_hash["windows"]),
            :date => options[:date]
          }
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
          plates = []
          transfer_map = [].tap do |t|
            source_uuid = json["plate_transfer"]["source"]["plate"]["uuid"]
            target_uuid = json["plate_transfer"]["target"]["plate"]["uuid"]
            json["plate_transfer"]["transfer_map"].each do |source_location, target_location|
              t << {
                "source_uuid" => source_uuid, "source_location" => source_location, 
                "target_uuid" => target_uuid, "target_location" => target_location
              }
            end
          end

          ["source", "target"].each do |key|
            plates << PlateJsonDecoder.call(json["plate_transfer"][key], options)
          end

          {:plates => plates, :transfer_map => transfer_map}
        end
      end


      module TransferPlatesToPlatesJsonDecoder
        def self.call(json, options)
          plates = []
          transfer_map = json["transfer_plates_to_plates"]["transfers"]
          ["sources", "targets"].each do |key|
            json["transfer_plates_to_plates"]["result"][key].each do |asset|
              plates << case asset.keys.first
              when "plate" then PlateJsonDecoder.call(asset, options) 
              when "tube_rack" then TubeRackJsonDecoder.call(asset, options)
              when "gel" then GelJsonDecoder.call(asset, options)
              end
            end
          end

          {:plates => plates, :transfer_map => transfer_map}
        end
      end


      module TubeRackTransferJsonDecoder
        def self.call(json, options)
          plates = []
          transfer_map = [].tap do |t|
            source_uuid = json["tube_rack_transfer"]["source"]["tube_rack"]["uuid"]
            target_uuid = json["tube_rack_transfer"]["target"]["tube_rack"]["uuid"]
            json["tube_rack_transfer"]["transfer_map"].each do |source_location, target_location|
              t << {
                "source_uuid" => source_uuid, "source_location" => source_location, 
                "target_uuid" => target_uuid, "target_location" => target_location
              }
            end
          end

          ["source", "target"].each do |key|
            plates << TubeRackJsonDecoder.call(json["tube_rack_transfer"][key], options)
          end

          {:plates => plates, :transfer_map => transfer_map}
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
