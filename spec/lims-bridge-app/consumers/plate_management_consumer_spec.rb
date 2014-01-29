require 'lims-bridge-app/consumers/spec_helper'
require 'lims-bridge-app/consumers/plate_management_consumer'
require 'lims-bridge-app/message_handlers/all'

module Lims::BridgeApp
  describe PlateManagementConsumer do
    include_context "consumer"

    context "success to route messages" do
      it_behaves_like "routing message", "*.*.plate.create", MessageHandlers::AssetCreationHandler
      it_behaves_like "routing message", "*.*.plate.createplate", MessageHandlers::AssetCreationHandler
      it_behaves_like "routing message", "*.*.plate.updateplate", MessageHandlers::AliquotsUpdateHandler

      it_behaves_like "routing message", "*.*.gel.create", MessageHandlers::AssetCreationHandler
      it_behaves_like "routing message", "*.*.gel.creategel", MessageHandlers::AssetCreationHandler
      it_behaves_like "routing message", "*.*.gel.updategel", MessageHandlers::AliquotsUpdateHandler

      it_behaves_like "routing message", "*.*.gelimage.create", MessageHandlers::GelImageHandler
      it_behaves_like "routing message", "*.*.gelimage.creategelimage", MessageHandlers::GelImageHandler
      it_behaves_like "routing message", "*.*.gelimage.updategelimage", MessageHandlers::GelImageHandler
      it_behaves_like "routing message", "*.*.updategelimagescore.updategelimagescore", MessageHandlers::GelImageHandler

      it_behaves_like "routing message", "*.*.tuberack.create", MessageHandlers::AssetCreationHandler 
      it_behaves_like "routing message", "*.*.tuberack.createtuberack", MessageHandlers::AssetCreationHandler 
      it_behaves_like "routing message", "*.*.tuberack.updatetuberack", MessageHandlers::AliquotsUpdateHandler 
      it_behaves_like "routing message", "*.*.tuberack.deletetuberack", MessageHandlers::AssetDeletionHandler 

      it_behaves_like "routing message", "*.*.order.create", MessageHandlers::OrderHandler 
      it_behaves_like "routing message", "*.*.order.createorder", MessageHandlers::OrderHandler 
      it_behaves_like "routing message", "*.*.order.updateorder", MessageHandlers::OrderHandler 

      it_behaves_like "routing message", "*.*.platetransfer.platetransfer", MessageHandlers::TransferHandler 
      it_behaves_like "routing message", "*.*.transferplatestoplates.transferplatestoplates", MessageHandlers::TransferHandler 
      it_behaves_like "routing message", "*.*.tuberacktransfer.tuberacktransfer", MessageHandlers::TransferHandler 
      it_behaves_like "routing message", "*.*.tuberackmove.tuberackmove", MessageHandlers::TubeRackMoveHandler 

      it_behaves_like "routing message", "*.*.labellable.create", MessageHandlers::LabellableHandler 
      it_behaves_like "routing message", "*.*.labellable.createlabellable", MessageHandlers::LabellableHandler 
      it_behaves_like "routing message", "*.*.bulkcreatelabellable.*", MessageHandlers::LabellableHandler 
      it_behaves_like "routing message", "*.*.udpatelabel.*", MessageHandlers::LabellableHandler 
      it_behaves_like "routing message", "*.*.bulkupdatelabel.*", MessageHandlers::LabellableHandler 

      it_behaves_like "routing message", "*.*.swapsamples.*", MessageHandlers::SwapSamplesHandler
    end

    context "fail to route messages" do
      it_behaves_like "failing to route message"
    end
  end
end
