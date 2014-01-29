module Lims::BridgeApp
  module MessageHandlers
    module SampleShared
      def sample_handler(&block)
        begin
          if resource.has_key?(:samples)
            resource[:samples].each do |sample_data|
              sample_uuid = sample_data[:uuid]
              sample = sample_data[:sample]
              block.call(sample, sample_uuid)
              bus.publish(sample_uuid)
            end
          else
            sample_uuid = resource[:uuid]
            sample = resource[:sample]
            block.call(sample, sample_uuid)
            bus.publish(sample_uuid)
          end
        rescue Sequel::Rollback, SequencescapeWrapper::AssetNotFound => e
          metadata.reject(:requeue => true)
          log.info("Error saving sample in Sequencescape: #{e}")
          raise Sequel::Rollback
        rescue SequencescapeWrapper::UnknownStudy => e
          metadata.reject
          log.error("Error saving sample in Sequencescape: #{e}")
          raise Sequel::Rollback
        else
          metadata.ack
          log.info("Sample message processed and acknowledged")
        end
      end
    end
  end
end
