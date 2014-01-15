require 'lims-bridge-app/consumers/spec_helper'
require 'lims-bridge-app/consumers/plate_management_consumer'
require 'lims-bridge-app/message_handlers/all'

module Lims::BridgeApp
  describe PlateManagementConsumer do
    include_context "plate management consumer"

    context "success to route messages" do
      it_behaves_like "routing message", "*.*.plate.create", MessageHandlers::AssetCreationHandler
      #it_behaves_like "routing message", "*.*.plate.updateplate", MessageHandlers::UpdateAliquotsHandler
      it_behaves_like "routing message", "*.*.gel.create", MessageHandlers::AssetCreationHandler
      #it_behaves_like "routing message", "*.*.gel.updategel", MessageHandlers::UpdateAliquotsHandler
      #it_behaves_like "routing message", "*.*.gelimage.create", MessageHandlers::GelImageHandler
      #it_behaves_like "routing message", "*.*.updategelimagescore.updategelimagescore", MessageHandlers::GelImageHandler
      it_behaves_like "routing message", "*.*.tuberack.create", MessageHandlers::AssetCreationHandler 
      #it_behaves_like "routing message", "*.*.tuberack.updatetuberack", MessageHandlers::UpdateAliquotsHandler 
      #it_behaves_like "routing message", "*.*.tuberack.deletetuberack", MessageHandlers::PlateDeleteHandler 
      #it_behaves_like "routing message", "*.*.order.create", MessageHandlers::OrderHandler 
      #it_behaves_like "routing message", "*.*.order.updateorder", MessageHandlers::OrderHandler 
      #it_behaves_like "routing message", "*.*.platetransfer.platetransfer", MessageHandlers::TransferHandler 
      #it_behaves_like "routing message", "*.*.transferplatestoplates.transferplatestoplates", MessageHandlers::TransferHandler 
      #it_behaves_like "routing message", "*.*.tuberacktransfer.tuberacktransfer", MessageHandlers::TransferHandler 
      #it_behaves_like "routing message", "*.*.tuberackmove.tuberackmove", MessageHandlers::TubeRackMoveHandler 
      #it_behaves_like "routing message", "*.*.labellable.create", MessageHandlers::LabellableHandler 
      #it_behaves_like "routing message", "*.*.bulkcreatelabellable.*", MessageHandlers::LabellableHandler 
      #it_behaves_like "routing message", "*.*.udpatelabel.*", MessageHandlers::LabellableHandler 
      #it_behaves_like "routing message", "*.*.bulkupdatelabel.*", MessageHandlers::LabellableHandler 
      #it_behaves_like "routing message", "*.*.swapsamples.*", MessageHandlers::SwapSamplesHandler
    end

    context "fail to route messages" do
      it "doesn't find the route from the routing key" do
        expect do
          consumer.send(:route_for, "dummy")
        end.to raise_error(BaseConsumer::NoRouteFound)
      end

      it "doesn't find the handler from the route" do
        expect do
          MessageHandlers.handler_for("dummy") 
        end.to raise_error(MessageHandlers::UndefinedHandler)
      end
    end
  end
end
