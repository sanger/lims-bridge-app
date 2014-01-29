require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/transfer_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-laboratory-app/laboratory/plate'

module Lims::BridgeApp::MessageHandlers
  describe TransferHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape wrapper"
    after { handler.call }

    let(:source_plate_uuid) { uuid [1,2,3,4,5] }
    let(:target_plate_uuid) { uuid [1,2,3,4,6] }
    let(:plates) {[
      {:plate => Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12), :uuid => source_plate_uuid, :sample_uuids => {}},
      {:plate => Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12), :uuid => target_plate_uuid, :sample_uuids => {}}
    ]}
      
    let(:transfer_map) {[
      {"source_uuid" => source_plate_uuid, "target_uuid" => target_plate_uuid, "source_location" => "A1", "target_location" => "B1"},
      {"source_uuid" => source_plate_uuid, "target_uuid" => target_plate_uuid, "source_location" => "A2", "target_location" => "B2"}
    ]}

    let(:resource) do
      {}.tap do |resource|
        resource[:plates] = plates
        resource[:transfer_map] = transfer_map
        resource[:date] = Time.now
      end
    end


    shared_context "create plates involved in the transfer" do
      before do
        plates.each do |plate_data|
          plate_id = wrapper.create_asset(plate_data[:plate], plate_data[:sample_uuids])
          wrapper.create_uuid(settings["plate_type"], plate_id, plate_data[:uuid])
        end
      end
    end


    context "with a valid call" do
      include_context "create plates involved in the transfer"      

      it "calls the methods involved in the transfer" do
        plates.each do |plate_data|
          bus.should_receive(:publish).with(plate_data[:uuid])
        end
        transfer_map.each do |transfer|
          sequencescape.should_receive(:create_asset_link).with(an_instance_of(Fixnum), an_instance_of(Fixnum))
          sequencescape.should_receive(:create_transfer_request).with(an_instance_of(Fixnum), an_instance_of(Fixnum))
        end
        metadata.should_receive(:ack)
      end
    end


    context "with an invalid call" do
      context "with an unknown asset" do
        it "rejects the message" do
          metadata.should_receive(:reject).with(:requeue => true)
        end
      end

      context "with an invalid location" do
        include_context "create plates involved in the transfer"

        let(:transfer_map) {[
          {"source_uuid" => source_plate_uuid, "target_uuid" => target_plate_uuid, "source_location" => "A1", "target_location" => "Z89"},
          {"source_uuid" => source_plate_uuid, "target_uuid" => target_plate_uuid, "source_location" => "X20", "target_location" => "B2"}
        ]}

        it "rejects the message" do
          # this corresponds to the publication of the plate 
          # as the update_aliquots operation worked but will be 
          # rollback after it blows up with the unknown location.
          plates.each do |plate_data|
            bus.should_receive(:publish).with(plate_data[:uuid])
          end
          metadata.should_receive(:reject).with(no_args)
        end
      end
    end
  end
end

