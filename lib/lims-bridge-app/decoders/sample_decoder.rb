require 'lims-bridge-app/base_decoder'
require 'lims-management-app/sample/sample'

module Lims::BridgeApp
  module Decoders
    class SampleDecoder < BaseDecoder

      private

      # @return [Lims::ManagementApp::Sample]
      def decode_sample
        Lims::ManagementApp::Sample.new.tap do |sample|
          resource_hash.each do |k,v|
            sample.send("#{k}=", v) if sample.respond_to?("#{k}=")
          end
        end
      end
    end

    class BulkSampleDecoder < SampleDecoder
      def decode_bulk_sample

      end
    end
  end
end
