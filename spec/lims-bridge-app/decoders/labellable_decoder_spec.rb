require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/labellable_decoder'

module Lims::BridgeApp::Decoders
  describe LabellableDecoder do
    include_context "labellable message"

    shared_examples_for "decoding the labellable" do
      it "decodes the labellable" do
        result[:labellable].name.should == "4fefaa90-5a9d-0131-974c-282066132de2" 
        result[:labellable].type.should == "resource"
        result[:labellable]["position 1"].should be_a(Lims::LaboratoryApp::Labels::Labellable::Label) 
        result[:labellable]["position 1"].type.should == "sanger-barcode"
        result[:labellable]["position 1"].value.should == "ND00000A"
        result[:labellable]["position 2"].should be_a(Lims::LaboratoryApp::Labels::Labellable::Label) 
        result[:labellable]["position 2"].type.should == "ean13-barcode"
        result[:labellable]["position 2"].value.should == "NC00000B"
      end
    end

    context "when creating a labellable" do
      let(:result) { described_class.decode(create_message) }

      it_behaves_like "decoding the resource", Lims::LaboratoryApp::Labels::Labellable
      it_behaves_like "decoding the date"
      it_behaves_like "decoding the uuid"
      it_behaves_like "decoding the labellable"
    end

    context "when bulk creating labellables" do
      let(:result) { described_class.decode(bulk_create_message) }

      it_behaves_like "decoding the date"

      it "decodes labellables" do
        result[:labellables].should be_a(Array)
        result[:labellables].each do |labellable|
          labellable.should be_a(Lims::LaboratoryApp::Labels::Labellable)
        end
      end
    end

    context "when create label" do
      let(:result) { described_class.decode(create_label_action_message) }

      it_behaves_like "decoding the date"

      it "decodes the labellable" do
        result[:labellable].should be_a(Lims::LaboratoryApp::Labels::Labellable)
        result[:labellable].name.should == "11111111-2222-3333-4444-666666666666"
        result[:labellable].type.should == "resource" 
        result[:labellable]["position 1"].should be_a(Lims::LaboratoryApp::Labels::Labellable::Label) 
        result[:labellable]["position 1"].type.should == "2d-barcode"
        result[:labellable]["position 1"].value.should == "2d-barcode-1234"
      end
    end

    context "when update label" do
      pending
    end

    context "when bulk update label" do
      pending
    end
  end
end
