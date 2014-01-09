require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/order_decoder'

module Lims::BridgeApp::Decoders
  describe OrderDecoder do
    include_context "order message"

    context "when creating an order" do
      let(:result) { described_class.decode(order_message) }

      it_behaves_like "decoding the resource", Lims::LaboratoryApp::Organization::Order
      it_behaves_like "decoding the date"
      it_behaves_like "decoding the uuid"
       
      it "decodes the order" do
        result[:order]["test"].size.should == 1
        result[:order]["test"][0].status.should == "done"
        result[:order]["test"][0].uuid.should == "a7efcf80-5b74-0131-978c-282066132de2"
        result[:order]["test2"].size.should == 1
        result[:order]["test2"][0].status.should == "pending"
        result[:order]["test2"][0].uuid.should == "a7efcf80-5b74-0131-978c-282066132de2"
      end
    end
  end
end
