require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/labels/labellable'

module Lims::BridgeApp
  module Decoders
    class LabellableDecoder < BaseDecoder

      private

      # @param [Hash] payload
      # @return [Lims::LaboratoryApp::Labels::Labellable]
      def decode_labellable(payload = @payload)
        Lims::LaboratoryApp::Labels::Labellable.new({
          :name => resource_hash["name"],
          :type => resource_hash["type"]
        }).tap do |labellable|
          resource_hash["labels"].each do |position, label_hash|
            labellable[position] = Lims::LaboratoryApp::Labels::Labellable::Label.new({
              :type => label_hash["type"],
              :value => label_hash["value"]
            })
          end
        end
      end

      # @return [Hash]
      def decode_bulk_create_labellable
        {:labellables => [].tap { |labellables|
          resource_hash["labellables"].each do |labellable|
            labellables << decode_labellable(labellable)          
          end
        }}
      end

      # @return [Lims::LaboratoryApp::Labels::Labellable]
      def decode_update_label
        @payload = resource_hash["result"]
        decode_labellable
      end

      # @return [Hash]
      def decode_bulk_update_label
        {:labellables => [].tap { |labellables|
          resource_hash["result"]["labellables"].each do |labellable|
            labellables << decode_labellable({"labellable" => labellable})
          end
        }}
      end
    end
  end
end
