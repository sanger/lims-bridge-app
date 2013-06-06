require 'lims-bridge-app/plate_creator/spec_helper'
require 'lims-bridge-app/plate_creator/stock_plate_consumer'
require 'lims-bridge-app/plate_creator/message_handlers/all'
require 'ostruct'

module Lims::BridgeApp::PlateCreator
  describe StockPlateConsumer do
    shared_examples_for "routing message" do |routing_key, object|
      let(:consumer) { described_class.new({}, {}) }
      let(:db) { mock(:db) }
      let(:log) { mock(:log) }
      let(:s2_resource) { mock(:s2_resource) }
      let(:metadata) { mock(:metadata).tap do |m|
        m.stub(:routing_key).and_return(routing_key)
      end
      }

      it "dispatches the message" do
        object.any_instance.should_receive(:call)
        consumer.send(:routing_message, metadata, s2_resource)
      end
    end

    it_behaves_like "routing message", "*.*.plate.create", MessageHandler::PlateHandler
    it_behaves_like "routing message", "*.*.tuberack.create", MessageHandler::PlateHandler 
    it_behaves_like "routing message", "*.*.tuberack.updatetuberack", MessageHandler::UpdateAliquotsHandler 
    it_behaves_like "routing message", "*.*.order.create", MessageHandler::OrderHandler 
    it_behaves_like "routing message", "*.*.order.updateorder", MessageHandler::OrderHandler 
    it_behaves_like "routing message", "*.*.platetransfer.platetransfer", MessageHandler::UpdateAliquotsHandler 
    it_behaves_like "routing message", "*.*.transferplatestoplates.transferplatestoplates", MessageHandler::UpdateAliquotsHandler 
    it_behaves_like "routing message", "*.*.tuberacktransfer.tuberacktransfer", MessageHandler::UpdateAliquotsHandler 
    it_behaves_like "routing message", "*.*.tuberackmove.tuberackmove", MessageHandler::TubeRackMoveHandler 
  end
end
