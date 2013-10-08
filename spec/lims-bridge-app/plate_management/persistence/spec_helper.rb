require 'lims-bridge-app/plate_management/spec_helper'
require 'lims-bridge-app/plate_management/sequencescape_updater'
require 'yaml'

shared_context "updater" do
  let(:db_settings) { YAML.load_file(File.join('config', 'database.yml'))['test'] }
  let(:bridge_settings) { YAML.load_file(File.join('config', 'bridge.yml'))['default']['plate_management'] }
  let!(:updater) do
    Class.new do 
      include Lims::BridgeApp::PlateManagement::SequencescapeUpdater 
      attr_accessor :db
      attr_accessor :settings
    end.new.tap do |o|
      o.db = Sequel.connect(db_settings)
      o.settings = bridge_settings
    end
  end
end

shared_context "prepare database for plate management" do
  include_context "prepare database"
  
  before do
    db[:study_samples].insert(:study_id => 1, :sample_id => 1)
    db[:study_samples].insert(:study_id => 1, :sample_id => 2)
    db[:study_samples].insert(:study_id => 1, :sample_id => 3)
    db[:study_samples].insert(:study_id => 1, :sample_id => 4)
    db[:study_samples].insert(:study_id => 1, :sample_id => 5)
    db[:study_samples].insert(:study_id => 1, :sample_id => 6)
  end
end

shared_context "source and target plate" do
  let(:number_of_rows) { 8 }
  let(:number_of_columns) { 12 }

  let(:sample_uuids) {{
    "A1" => ["11111111-0000-0000-0000-111111111111"],
    "B2" => ["11111111-0000-0000-0000-222222222222"],
    "C3" => ["11111111-0000-0000-0000-333333333333"],
    "D4" => ["11111111-0000-0000-0000-444444444444"]
  }}

  let(:source_plate_uuid) { "11111111-2222-3333-4444-555555555555" }
  let(:source_plate) do
    Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows, :number_of_columns => number_of_columns).tap do |plate|
      plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
      plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
      plate["C3"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
      plate["D4"] << Lims::LaboratoryApp::Laboratory::Aliquot.new
    end
  end

  let(:target_plate_uuid) { "11111111-2222-3333-4444-666666666666" }
  let(:target_plate) {
    Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows, :number_of_columns => number_of_columns)
  }
end