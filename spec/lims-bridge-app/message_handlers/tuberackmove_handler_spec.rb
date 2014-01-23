require 'lims-bridge-app/message_handlers/spec_helper'
require 'lims-bridge-app/message_handlers/tuberackmove_handler'
require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-laboratory-app/laboratory/plate'

module Lims::BridgeApp::MessageHandlers
  describe TubeRackMoveHandler do
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
      
    let(:moves) {[
      {"source_uuid" => source_plate_uuid, "target_uuid" => target_plate_uuid, "source_location" => "A1", "target_location" => "B1"},
      {"source_uuid" => source_plate_uuid, "target_uuid" => target_plate_uuid, "source_location" => "A2", "target_location" => "B2"}
    ]}

    let(:resource) do
      {}.tap do |resource|
        resource[:moves] = moves
        resource[:date] = Time.now
      end
    end


    shared_context "create racks involved in the move transfer" do
      before do
        plates.each do |plate_data|
          plate_id = wrapper.create_asset(plate_data[:plate], plate_data[:sample_uuids])
          wrapper.create_uuid(settings["plate_type"], plate_id, plate_data[:uuid])
        end
      end
    end


    context "with a valid call" do
      include_context "create racks involved in the move transfer"      

      it "calls the methods involved in the transfer" do
        moves.each do |move|
          sequencescape.should_receive(:move_well).with(move["source_uuid"], move["source_location"], move["target_uuid"], move["target_location"]).and_call_original
          bus.should_receive(:publish).with(move["source_uuid"])
          bus.should_receive(:publish).with(move["target_uuid"])
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
    end
  end
end
