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

      # @return [Lims::LaboratoryApp::Labels::Labellable]
      def decode_update_label
        decode_labellable(resource_hash["result"])
      end
    end

    class CreateLabelDecoder < LabellableDecoder
      def decode_create_label
        @payload = resource_hash["result"]
        decode_labellable
      end
    end

    class BulkCreateLabellableDecoder < LabellableDecoder
      # @return [Hash]
      def decode_bulk_create_labellable
        {:labellables => [].tap { |labellables|
          resource_hash["labellables"].each do |labellable|
            labellables << decode_labellable(labellable)          
          end
        }}
      end
    end

    class BulkUpdateLabelDecoder < LabellableDecoder
      # @return [Hash]
      def decode_bulk_update_label
        {:labellables => [].tap { |labellables|
          resource_hash["result"]["labellables"].each do |labellable|
            labellables << decode_labellable(labellable)
          end
        }}
      end
    end

    UpdateLabelDecoder = Class.new(LabellableDecoder)
  end
end
