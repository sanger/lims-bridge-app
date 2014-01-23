require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/labellable_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-laboratory-app/labels/labellable'

module Lims::BridgeApp::MessageHandlers
  describe LabellableHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape wrapper"

    let(:asset_uuid) { uuid [1,2,3,4,5] }
    let(:labellable_uuid) { uuid [1,2,3,4,6] }
    let(:labellable) {
      Lims::LaboratoryApp::Labels::Labellable.new(:name => asset_uuid, :type => "resource").tap { |l|
        l["front"] = Lims::LaboratoryApp::Labels::Labellable::Label.new({
          :type => settings["sanger_barcode_type"],
          :value => barcode_value 
        })
      }
    }

    after { handler.call }

    context "with a valid call" do
      include_context "create an asset"
      let(:barcode_value) { "WD123456A" }

      context "with one labellable" do
        let(:resource) do
          {}.tap do |resource|
            resource[:labellable] = labellable
            resource[:uuid] = labellable_uuid 
            resource[:date] = Time.now
          end
        end

        before do
          bus.should_receive(:publish).with("11111111-2222-3333-4444-555555555555")
          metadata.should_receive(:ack)
        end

        it "calls the barcode_an_asset method" do
          sequencescape.should_receive(:barcode_an_asset).with(labellable).and_call_original 
        end
      end

      context "with an array of labellables" do
        let(:labellables) do
          [].tap do |l|
            5.times do
              l << Lims::LaboratoryApp::Labels::Labellable.new(:name => asset_uuid, :type => "resource")
            end
          end
        end
        let(:resource) do
          {}.tap do |resource|
            resource[:labellables] = labellables
            resource[:date] = Time.now
          end
        end

        before do
          5.times { bus.should_receive(:publish).with("11111111-2222-3333-4444-555555555555") }
          metadata.should_receive(:ack)
        end

        it "calls 5 times the barcode_an_asset method" do
          labellables.each do |labellable|
            sequencescape.should_receive(:barcode_an_asset).with(labellable).and_call_original
          end
        end
      end
    end


    context "with an invalid call" do
      let(:resource) do
        {}.tap do |resource|
          resource[:labellable] = labellable
          resource[:uuid] = labellable_uuid 
          resource[:date] = Time.now
        end
      end

      context "with an unknown asset" do
        let(:barcode_value) { "WD123456A" }
        it "rejects the message" do
          metadata.should_receive(:reject).with(:requeue => true)
        end
      end

      context "with an invalid sanger barcode" do
        include_context "create an asset"
        let(:barcode_value) { "ZZ123456A" }
        it "rejects the message" do
          metadata.should_receive(:reject)
        end
      end
    end
  end
end

