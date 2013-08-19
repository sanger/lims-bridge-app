require 'lims-bridge-app/plate_creator/persistence/spec_helper'
require 'lims-laboratory-app/laboratory/plate'

module Lims::BridgeApp::PlateCreator
  describe "Moves tube between tuberacks" do
    include_context "prepare database for plate management"
    include_context "updater"

    let(:source_plate_uuid) { "11111111-2222-3333-4444-555555555555" }
    let(:sample_uuids) {{
      "A1" => ["11111111-0000-0000-0000-111111111111"],
      "B2" => ["11111111-0000-0000-0000-222222222222"],
      "C3" => ["11111111-0000-0000-0000-333333333333"],
      "D4" => ["11111111-0000-0000-0000-444444444444"]
    }}
    let(:number_of_rows) { 8 }
    let(:number_of_columns) { 12 }
    let(:source_plate) do
      Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows, :number_of_columns => number_of_columns).tap do |plate|
        plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
        plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
        plate["C3"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
        plate["D4"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
      end
    end
    let(:target_plate) { 
      Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows, :number_of_columns => number_of_columns)
    }
    let(:target_plate_uuid) { "11111111-2222-3333-4444-666666666666" }
    let(:moves) {
      [
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
      ]
    }

    context "moves wells between plates in sequencescape" do
      before do 
        updater.create_plate_in_sequencescape(source_plate, source_plate_uuid, Time.now, sample_uuids)
        updater.create_plate_in_sequencescape(target_plate, target_plate_uuid, Time.now, {})
        moves.each do |move|
          updater.move_wells_in_sequencescape(move, Time.now)
        end
      end

      it "moves the wells" do
        moves.each do |move|
          # checks if the source locations is empty
          target_plate_id = updater.plate_id_by_uuid(move["target_uuid"])
          target_location = move["target_location"]

          target_map_id = updater.get_map_id(target_location, target_plate_id)

          target_well_id = db[:assets].select(:id).where(
            {:map_id  => target_map_id,
             :id      => db[:container_associations].select(
               :content_id).where(:container_id => target_plate_id)
            }).first[:id]
          target_well_id.should_not be_nil

          sample_id = db[:aliquots].select(:sample_id).where(
            :receptacle_id => target_well_id).first[:sample_id]
          sample_id.should_not be_nil
        end
      end
    end
  end
end
