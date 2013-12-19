require 'lims-bridge-app/plate_management/spec_helper'
require 'lims-bridge-app/plate_management/stock_plate_consumer'
require 'lims-bridge-app/plate_management/message_handlers/all'

module Lims::BridgeApp::PlateManagement
  describe StockPlateConsumer do
    shared_examples_for "routing message" do |routing_key, object|
      let(:consumer) { described_class.new({"sequencescape" => [{:routing_key => nil}]}, {}, {}) }
      let(:db) { mock(:db) }
      let(:log) { mock(:log) }
      let(:s2_resource) { mock(:s2_resource) }
      let(:metadata) { mock(:metadata).tap do |m|
        m.stub(:routing_key).and_return(routing_key)
      end
      }

      it "dispatches the message" do
        Lims::BridgeApp::MessageBus.any_instance.stub(:message_bus_connection)
        object.any_instance.should_receive(:call)
        consumer.send(:route_message, metadata, s2_resource)
      end
    end

    it_behaves_like "routing message", "*.*.plate.create", MessageHandler::PlateHandler
    it_behaves_like "routing message", "*.*.plate.updateplate", MessageHandler::UpdateAliquotsHandler
    it_behaves_like "routing message", "*.*.gel.create", MessageHandler::PlateHandler
    it_behaves_like "routing message", "*.*.gel.updategel", MessageHandler::UpdateAliquotsHandler
    it_behaves_like "routing message", "*.*.gelimage.create", MessageHandler::GelImageHandler
    it_behaves_like "routing message", "*.*.updategelimagescore.updategelimagescore", MessageHandler::GelImageHandler
    it_behaves_like "routing message", "*.*.tuberack.create", MessageHandler::PlateHandler 
    it_behaves_like "routing message", "*.*.tuberack.updatetuberack", MessageHandler::UpdateAliquotsHandler 
    it_behaves_like "routing message", "*.*.tuberack.deletetuberack", MessageHandler::PlateDeleteHandler 
    it_behaves_like "routing message", "*.*.order.create", MessageHandler::OrderHandler 
    it_behaves_like "routing message", "*.*.order.updateorder", MessageHandler::OrderHandler 
    it_behaves_like "routing message", "*.*.platetransfer.platetransfer", MessageHandler::TransferHandler 
    it_behaves_like "routing message", "*.*.transferplatestoplates.transferplatestoplates", MessageHandler::TransferHandler 
    it_behaves_like "routing message", "*.*.tuberacktransfer.tuberacktransfer", MessageHandler::TransferHandler 
    it_behaves_like "routing message", "*.*.tuberackmove.tuberackmove", MessageHandler::TubeRackMoveHandler 
    it_behaves_like "routing message", "*.*.labellable.create", MessageHandler::LabellableHandler 
    it_behaves_like "routing message", "*.*.bulkcreatelabellable.*", MessageHandler::LabellableHandler 
    it_behaves_like "routing message", "*.*.udpatelabel.*", MessageHandler::LabellableHandler 
    it_behaves_like "routing message", "*.*.bulkupdatelabel.*", MessageHandler::LabellableHandler 
    it_behaves_like "routing message", "*.*.swapsamples.*", MessageHandler::SwapSamplesHandler 
  end
end
