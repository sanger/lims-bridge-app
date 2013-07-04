require 'lims-bridge-app/plate_creator/persistence/spec_helper'
require 'lims-bridge-app/plate_creator/persistence/persistence_shared'

module Lims::BridgeApp::PlateCreator
  describe "Swapping samples" do
    include_context "prepare database for plate management"
    include_context "updater"

    context "swap samples" do
      let(:plate_uuid) { "11111111-2222-3333-4444-555555555555" }
      let(:sample_uuids) {{
        "A1" => ["11111111-0000-0000-0000-111111111111"],
        "B2" => ["11111111-0000-0000-0000-222222222222"],
        "C3" => ["11111111-0000-0000-0000-333333333333"],
        "D4" => ["11111111-0000-0000-0000-444444444444"]
      }}
      let(:location_samples) {{
        "A1" => "11111111-0000-0000-0000-444444444444",
        "B2" => "11111111-0000-0000-0000-333333333333",
        "C3" => "11111111-0000-0000-0000-222222222222",
        "D4" => "11111111-0000-0000-0000-111111111111"
      }}
      let(:swaps) {{
        "11111111-0000-0000-0000-111111111111" => "11111111-0000-0000-0000-444444444444",
        "11111111-0000-0000-0000-222222222222" => "11111111-0000-0000-0000-333333333333",
        "11111111-0000-0000-0000-333333333333" => "11111111-0000-0000-0000-222222222222",
        "11111111-0000-0000-0000-444444444444" => "11111111-0000-0000-0000-111111111111"
      }}
      let(:number_of_rows) { 8 }
      let(:number_of_columns) { 12 }
      let(:plate) do
        Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows, :number_of_columns => number_of_columns).tap do |plate|
          plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
          plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
          plate["C3"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
          plate["D4"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
        end
      end

      before do 
        updater.create_plate_in_sequencescape(plate, plate_uuid, Time.now, sample_uuids)
        updater.swap_samples(plate_uuid, location_samples, swaps, Time.now)
      end

      let(:well_ids) {
        db[:uuids].where(
          :external_id => plate_uuid
        ).join(
          :container_associations, :container_id => :resource_id
        ).join(
          :assets, :id => :content_id
        ).join(
          :maps, :id => :map_id
        ).select(
          :maps__description, :assets__id 
        ).all.inject({}) { |m,e| m.merge({e[:description] => e[:id]}) }
      }

      shared_examples_for "sample in location" do |sample_uuid, location|
        it "has the sample #{sample_uuid} in the location #{location}" do
          aliquot = db[:aliquots].where(
            :receptacle_id => well_ids[location], :resource_type => "Sample"
          ).join(
            :uuids, :resource_id => :sample_id
          ).first

          aliquot[:external_id].should == sample_uuid 
        end
      end

      context "valid" do
        it_behaves_like "sample in location", "11111111-0000-0000-0000-444444444444", "A1"
        it_behaves_like "sample in location", "11111111-0000-0000-0000-333333333333", "B2"
        it_behaves_like "sample in location", "11111111-0000-0000-0000-222222222222", "C3"
        it_behaves_like "sample in location", "11111111-0000-0000-0000-111111111111", "D4"
      end
    end
  end
end
