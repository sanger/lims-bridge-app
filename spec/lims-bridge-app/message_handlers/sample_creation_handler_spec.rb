require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/sample_creation_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-management-app/sample/sample'

module Lims::BridgeApp::MessageHandlers
  describe SampleCreationHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape wrapper"

    let(:sanger_sample_id) { "testblabla-456" }
    let(:study_name) { "testblabla" }
    let(:sample_uuid) { uuid [1,2,3,4,6] }
    let(:sample) do
      Lims::ManagementApp::Sample.new.tap do |s|
        s.state = "published"
        s.sanger_sample_id = sanger_sample_id
      end
    end
    let(:resource) do
      {}.tap do |resource|
        resource[:sample] = sample
        resource[:uuid] = sample_uuid 
        resource[:date] = Time.now
      end
    end


    context "when getting the study name from the sanger sample id" do
      it "returns the study name" do
        handler.send(:study_name, sanger_sample_id).should == study_name 
      end
    end


    context "with a valid call" do
      after { handler.call }
      before do
        Lims::BridgeApp::SequencescapeModel::StudyMetadata.insert(:study_name_abbreviation => study_name, :study_id => 1)
        Lims::BridgeApp::SequencescapeModel::StudyMetadata.insert(:study_name_abbreviation => study_name, :study_id => 2)
      end

      context "with one sample" do
        before do
          2.times { bus.should_receive(:publish).with(an_instance_of(String)) }
          bus.should_receive(:publish).with(sample_uuid)
          metadata.should_receive(:ack)
        end

        it "calls the methods to create sample" do
          sequencescape.should_receive(:create_sample).with(sample).and_call_original 
          sequencescape.should_receive(:create_uuid).with(settings["sample_type"], an_instance_of(Fixnum), sample_uuid).and_call_original 
          sequencescape.should_receive(:create_study_sample).with(an_instance_of(Fixnum), study_name).and_call_original 
          2.times { sequencescape.should_receive(:create_uuid).with(settings["study_sample_type"], an_instance_of(Fixnum), an_instance_of(String)).and_call_original }
        end
      end


      context "with an array of samples" do
        let(:samples) do
          [].tap do |samples|
            (1..5).to_a.each do |i|
              samples << {:sample => Lims::ManagementApp::Sample.new.tap { |s|
                s.state = "published"
                s.sanger_sample_id = "#{sanger_sample_id}#{i}" 
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
          samples.each do |sample|
            2.times { bus.should_receive(:publish).with(an_instance_of(String)) }
            bus.should_receive(:publish).with(sample[:uuid])
          end
          metadata.should_receive(:ack)
        end

        it "calls the methods to create sample" do
          samples.each do |sample_data|
            sequencescape.should_receive(:create_sample).with(sample_data[:sample]).and_call_original 
            sequencescape.should_receive(:create_uuid).with(settings["sample_type"], an_instance_of(Fixnum), sample_data[:uuid]).and_call_original 
            sequencescape.should_receive(:create_study_sample).with(an_instance_of(Fixnum), study_name).and_call_original 
            2.times { sequencescape.should_receive(:create_uuid).with(settings["study_sample_type"], an_instance_of(Fixnum), an_instance_of(String)).and_call_original }
          end
        end
      end
    end


    context "with an invalid call" do
      after { handler.call }

      context "with unknown study" do
        it "rejects the message" do
          metadata.should_receive(:reject).with(no_args)
        end
      end
    end
  end
end
