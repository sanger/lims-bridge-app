require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/sample_update_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-management-app/sample/sample'

module Lims::BridgeApp::MessageHandlers
  describe SampleUpdateHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape wrapper"

    let(:sample_uuid) { uuid [1,2,3,4,6] }
    let(:sample) do
      Lims::ManagementApp::Sample.new.tap do |s|
        s.state = "published"
        s.sanger_sample_id = "test-123"
      end
    end

    let(:resource) do
      {}.tap do |resource|
        resource[:sample] = sample
        resource[:uuid] = sample_uuid 
        resource[:date] = Time.now
      end
    end
    
    after { handler.call }


    context "with a valid call" do
      context "with one sample" do
        before do
          sample_id = wrapper.create_sample(sample)
          wrapper.create_uuid(settings["sample_type"], sample_id, sample_uuid)
        end

        it "calls the update_sample method" do
          sequencescape.should_receive(:update_sample).with(sample, sample_uuid).and_call_original 
          bus.should_receive(:publish).with(sample_uuid)
          metadata.should_receive(:ack)
        end
      end

      context "with an array of samples" do
        let(:samples) do
          [].tap do |samples|
            (1..5).to_a.each do |i|
              samples << {:sample => Lims::ManagementApp::Sample.new.tap { |s|
                s.state = "published"
                s.sanger_sample_id = "test-#{i}" 
              },
              :uuid => uuid([1,0,0,0,i])}
            end
          end
        end

        let(:resource) do
          {}.tap do |resource|
            resource[:samples] = samples
            resource[:date] = Time.now
          end
        end

        before do
          samples.each do |sample_data|
            sample_id = wrapper.create_sample(sample_data[:sample])
            wrapper.create_uuid(settings["sample_type"], sample_id, sample_data[:uuid])
          end
        end

        it "calls the methods to create sample" do
          samples.each do |sample_data|
            bus.should_receive(:publish).with(sample_data[:uuid])
            sequencescape.should_receive(:update_sample).with(sample_data[:sample], sample_data[:uuid]).and_call_original 
          end
          metadata.should_receive(:ack)
        end
      end
    end


    context "with an invalid call" do
      context "with unknown samples" do
        it "rejects the message" do
          metadata.should_receive(:reject).with(:requeue => true)
        end
      end
    end
  end
end
