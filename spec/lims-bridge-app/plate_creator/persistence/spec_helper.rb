require 'lims-bridge-app/plate_creator/spec_helper'
require 'lims-bridge-app/plate_creator/sequencescape_updater'
require 'yaml'

shared_context "updater" do
  let(:db_settings) { YAML.load_file(File.join('config', 'database.yml'))['test'] }
  let!(:updater) do
    Class.new do 
      include Lims::BridgeApp::PlateCreator::SequencescapeUpdater 
      attr_accessor :db
    end.new.tap do |o|
      o.db = Sequel.connect(db_settings)
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
