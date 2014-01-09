require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/labels/labellable'

module Lims::BridgeApp
  module Decoders
    class LabellableDecoder < BaseDecoder

      private

      # @param [Hash] payload
      # @return [Lims::LaboratoryApp::Labels::Labellable]
      def decode_labellable(labellable_hash = resource_hash)
        Lims::LaboratoryApp::Labels::Labellable.new({
          :name => labellable_hash["name"],
          :type => labellable_hash["type"]
        }).tap do |labellable|
          labellable_hash["labels"].each do |position, label_hash|
            labellable[position] = Lims::LaboratoryApp::Labels::Labellable::Label.new({
              :type => label_hash["type"],
              :value => label_hash["value"]
            })
          end
        end
      end
    end

    %w{create update}.to_a.each do |action|
      class_eval %Q{
        class #{action.capitalize}LabelDecoder < LabellableDecoder
          def decode_#{action}_label
            @payload = resource_hash["result"]
            decode_labellable
          end
        end
      }
    end

    %w{bulk_create_labellable bulk_update_label}.to_a.each do |action|
      class_eval %Q{
        class #{action.split("_").map { |a| a.capitalize! }.join("")}Decoder < LabellableDecoder
          def decode_#{action}
            {:labellables => [].tap { |labellables|
              resource_hash["result"]["labellables"].each do |labellable|
                labellables << decode_labellable(labellable)
              end
            }}
          end
        end
      }
    end
  end
end
