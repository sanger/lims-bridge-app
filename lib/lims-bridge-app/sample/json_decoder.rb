require 'lims-management-app/sample/sample'
require 'lims-bridge-app/base_json_decoder'
require 'json'

module Lims::BridgeApp
  module SampleManagement
    module JsonDecoder
      include BaseJsonDecoder

      module SampleJsonDecoder
        def self.call(json)
          sample_hash = json["sample"]
          sample(sample_hash)
        end

        def self.sample(sample_hash)
          sample = Lims::ManagementApp::Sample.new
          sample_hash.each do |k,v|
            sample.send("#{k}=", v) if sample.respond_to?("#{k}=")
          end

          {:sample => sample, :uuid => sample_hash["uuid"]}
        end
      end

      module BulkCreateSampleJsonDecoder
        def self.call(json)
          bulk_sample_hash = json["bulk_create_sample"]
          samples_hash = bulk_sample_hash["result"]["samples"]
          samples = []
          samples_hash.each do |sample_hash|
            samples << JsonDecoder::SampleJsonDecoder.sample(sample_hash)        
          end

          {:samples => samples}
        end
      end
    end
  end
end
