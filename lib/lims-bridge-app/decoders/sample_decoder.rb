require 'lims-bridge-app/base_decoder'
require 'lims-management-app/sample/sample'

module Lims::BridgeApp
  module Decoders
    class SampleDecoder < BaseDecoder

      private

      # @return [Lims::ManagementApp::Sample]
      def decode_sample(sample_hash = resource_hash)
        Lims::ManagementApp::Sample.new.tap do |sample|
          sample_hash.each do |k,v|
            sample.send("#{k}=", v) if sample.respond_to?("#{k}=")
          end
        end
      end
    end

    module BulkSampleDecoder
      def decode_bulk_sample
        samples_hash = resource_hash["result"]["samples"]
        samples = []
        samples_hash.each do |sample_hash|
          samples << SampleDecoder.new({"sample" => sample_hash}, @options).call
        end
        {:samples => samples}
      end
    end

    %w{create update delete}.each do |action|
      class_eval %Q{
        class Bulk#{action.capitalize}SampleDecoder < SampleDecoder
          include BulkSampleDecoder

          def decode_bulk_#{action}_sample
            decode_bulk_sample
          end
        end
      }
    end
  end
end
