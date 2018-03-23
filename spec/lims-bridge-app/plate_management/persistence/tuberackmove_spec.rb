require 'lims-bridge-app/plate_management/persistence/spec_helper'
require 'lims-laboratory-app/laboratory/plate'

module Lims::BridgeApp::PlateManagement
  describe "Moves tube between tuberacks" do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "source and target plate"

    let(:moves) {[
        { "source_uuid"          => source_plate_uuid,
          "source_location" => "A1",
          "target_uuid"          => target_plate_uuid,
          "target_location" => "B9"},
        { "source_uuid"          => source_plate_uuid,
          "source_location" => "B2",
          "target_uuid"          => target_plate_uuid,
          "target_location" => "F7"},
        { "source_uuid"          => source_plate_uuid,
          "source_location" => "C3",
          "target_uuid"          => target_plate_uuid,
          "target_location" => "D5"},
        { "source_uuid"          => source_plate_uuid,
          "source_location" => "D4",
          "target_uuid"          => target_plate_uuid,
          "target_location" => "A3"}
    ]}

    context "moves wells between plates in sequencescape" do
      before do 
        updater.create_plate_in_sequencescape(source_plate, source_plate_uuid, Time.now, sample_uuids)
        updater.create_plate_in_sequencescape(target_plate, target_plate_uuid, Time.now, {})
        moves.each do |move|
          updater.move_wells_in_sequencescape(move, Time.now)
        end
      end

      it "empties the source plate after the move" do
        moves.each do |move|
          # check if the source locations is empty ie no aliquots
          source_plate_id = updater.plate_id_by_uuid(move["source_uuid"])
          source_location = move["source_location"]
          source_map_id = updater.get_map_id(source_location, source_plate_id)
          source_well_id = db[:assets].select(:assets__id).join(:container_associations, :content_id => :assets__id).where({
            :container_id => source_plate_id,
            :map_id => source_map_id
          }).first[:id]

          db[:aliquots].where(:receptacle_id => source_well_id).count.should == 0

          # check if the source plate has all its wells after the move
          db[:assets].join(:container_associations, :content_id => :assets__id).where({
            :container_id => source_plate_id
          }).count.should == 96
        end
      end

      it "fills the target plate after the move" do
        moves.each do |move|
          # check if the target locations is not empty
          target_plate_id = updater.plate_id_by_uuid(move["target_uuid"])
          target_location = move["target_location"]
          target_map_id = updater.get_map_id(target_location, target_plate_id)
          target_well_id = db[:assets].select(:assets__id).join(:container_associations, :content_id => :assets__id).where({
            :container_id => target_plate_id,
            :map_id => target_map_id
          }).first[:id]

          db[:aliquots].where(:receptacle_id => target_well_id).count.should == 1

          # check if the target plate has all its wells after the move
          db[:assets].join(:container_associations, :content_id => :assets__id).where({
            :container_id => target_plate_id
          }).count.should == 96
        end
      end
    end
  end
end
