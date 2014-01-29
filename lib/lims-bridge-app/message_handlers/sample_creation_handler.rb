require 'lims-bridge-app/base_handler'
require 'lims-bridge-app/message_handlers/sample_shared'

module Lims::BridgeApp
  module MessageHandlers
    class SampleCreationHandler < BaseHandler
      include SampleShared

      private

      def _call_in_transaction
        sample_handler do |sample, sample_uuid|
          sample_id = sequencescape.create_sample(sample) 
          sequencescape.create_uuid(settings["sample_type"], sample_id, sample_uuid)  
          study_name = study_name(sample.sanger_sample_id)
          study_sample_uuids = sequencescape.create_study_sample(sample_id, study_name)
          study_sample_uuids.each do |study_sample_uuid|
            bus.publish(study_sample_uuid)
          end
        end
      end

      # @param [String] sanger_sample_id
      # @return [String]
      def study_name(sanger_sample_id)
        sanger_sample_id.match(/^(.*)-[0-9]+$/)[1] 
      end
    end
  end
end
