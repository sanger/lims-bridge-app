require 'lims-bridge-app/spec_helper'

module Lims::BridgeApp
  shared_context "sequencescape wrapper" do
    let(:settings) { YAML.load_file(File.join('config', 'bridge.yml'))["default"] }
    let(:date) { Time.now.utc.to_s }
    let(:wrapper) do 
      SequencescapeWrapper.new(settings).tap do |w|
        w.date = date 
      end
    end
  end


  shared_examples_for "changing table" do |table, quantity|
    it "updates the table #{table} by #{quantity} records" do
      expect do
        result
      end.to change { db[table.to_sym].count }.by(quantity)
    end
  end


  shared_context "a plate" do
    let(:container) {
      Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12).tap { |plate|
        plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 10, :type => "DNA")
        plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 15, :type => "DNA")
        plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 100, :type => "solvent")
        plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 20, :type => "solvent")
        plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 25, :type => "RNA", :out_of_bounds => {:concentration => 4.0})
        plate["C3"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 30, :type => "NA")
      }
    }

    let(:sample_uuids) {{
      "A1" => [uuid([1,0,0,0,1]), uuid([1,0,0,0,2])],
      "B2" => [uuid([1,0,0,0,3])],
      "C3" => [uuid([1,0,0,0,4])]
    }}
  end


  shared_context "create a gel" do
    let(:gel) { Lims::LaboratoryApp::Laboratory::Gel.new(:number_of_rows => 8, :number_of_columns => 12) }
    let(:gel_uuid) { uuid [1,2,3,4,6] }

    before do
      gel_id = wrapper.create_asset(gel, {})
      wrapper.create_uuid(settings["gel_type"], gel_id, gel_uuid)
    end
  end


  shared_context "sample uuids and study samples" do
    before do
      (1..4).to_a.each do |i|
        SequencescapeModel::Uuid.insert(:resource_type => settings["sample_type"], :external_id => uuid([1,0,0,0,i]), :resource_id => i)
        SequencescapeModel::StudySample.insert(:sample_id => i, :study_id => 1)
      end
    end
  end


  shared_context "create an asset" do
    include_context "a plate"
    include_context "sample uuids and study samples"

    before do
      asset_id = wrapper.create_asset(container, sample_uuids)
      wrapper.create_uuid(settings["plate_type"], asset_id, asset_uuid)
    end
  end
end
