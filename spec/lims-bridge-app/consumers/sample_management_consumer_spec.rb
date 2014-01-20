require 'lims-bridge-app/consumers/spec_helper'
require 'lims-bridge-app/consumers/sample_management_consumer'
require 'lims-bridge-app/message_handlers/all'

module Lims::BridgeApp
  describe SampleManagementConsumer do
    include_context "consumer"

    context "success to route messages" do
      it_behaves_like "routing message", "*.*.sample.create", MessageHandlers::SampleCreationHandler
      it_behaves_like "routing message", "*.*.sample.createsample", MessageHandlers::SampleCreationHandler
      it_behaves_like "routing message", "*.*.sample.updatesample", MessageHandlers::SampleUpdateHandler
      it_behaves_like "routing message", "*.*.sample.deletesample", MessageHandlers::SampleDeletionHandler

      it_behaves_like "routing message", "*.*.bulkcreatesample.*", MessageHandlers::SampleCreationHandler
      it_behaves_like "routing message", "*.*.bulkupdatesample.*", MessageHandlers::SampleUpdateHandler
      it_behaves_like "routing message", "*.*.bulkdeletesample.*", MessageHandlers::SampleDeletionHandler
    end

    context "fail to route messages" do
      it_behaves_like "failing to route message"
    end
  end
end
