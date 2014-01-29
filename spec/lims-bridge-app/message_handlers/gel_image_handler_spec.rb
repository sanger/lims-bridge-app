require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/gel_image_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-quality-app/gel-image/gel_image'

module Lims::BridgeApp::MessageHandlers
  describe GelImageHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape wrapper"
    after { handler.call }

    let(:scores) {{"C1" => "pass", "C2" => "fail", "C3" => "degraded", "C4" => "partially degraded"}}
    let(:gel_image) { Lims::QualityApp::GelImage.new(:gel_uuid => gel_uuid, :scores => scores) }
    let(:gel_image_uuid) { uuid [1,2,3,4,6] }
    let(:resource) do
      {}.tap do |resource|
        resource[:gel_image] = gel_image
        resource[:uuid] = gel_image_uuid
        resource[:date] = Time.now
      end
    end

    context "with a valid call" do
      include_context "create a gel"
      let(:gel) { Lims::LaboratoryApp::Laboratory::Gel.new(:number_of_rows => 8, :number_of_columns => 12) }

      before do
        metadata.should_receive(:ack)
      end

      it "calls the update_gel_scores method" do
        sequencescape.should_receive(:update_gel_scores).with(gel_image).and_call_original 
      end
    end


    context "with an invalid call" do
      context "with an unknown asset" do
        let(:gel_uuid) { uuid [1,2,3,4,5] }
        it "rejects the message" do
          metadata.should_receive(:reject).with(:requeue => true)
        end
      end
    end
  end
end
