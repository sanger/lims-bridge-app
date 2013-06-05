require 'lims-bridge-app/plate_creator/spec_helper'
require 'lims-bridge-app/plate_creator/stock_plate_consumer'
require 'ostruct'

module Lims::BridgeApp::PlateCreator
  describe StockPlateConsumer do
    shared_examples_for "routing message" do |routing_key, method|
      let(:consumer) { described_class.new({}, {}) }
      let(:s2_resource) { mock(:s2_resource) }
      let(:metadata) { mock(:metadata).tap do |m|
        m.stub(:routing_key).and_return(routing_key)
      end
      }

      it "dispatches the message" do
        consumer.should_receive(method).with(metadata, s2_resource)
        consumer.send(:routing_message, metadata, s2_resource)
      end
    end

    it_behaves_like "routing message", "*.*.plate.create", "plate_message_handler"
    it_behaves_like "routing message", "*.*.tuberack.create", "plate_message_handler"
    it_behaves_like "routing message", "*.*.tuberack.updatetuberack", "update_like_message_handler"
    it_behaves_like "routing message", "*.*.order.create", "order_message_handler"
    it_behaves_like "routing message", "*.*.order.updateorder", "order_message_handler"
    it_behaves_like "routing message", "*.*.platetransfer.platetransfer", "update_like_message_handler"
    it_behaves_like "routing message", "*.*.transferplatestoplates.transferplatestoplates", "update_like_message_handler"
  end
end
