require 'lims-bridge-app/message_handlers/spec_helper'

shared_context "sequencescape sample study seeds" do
  before do
    study_id = db[:studies].insert(:name => "study 1")

    (1..6).to_a.each do |i|
      sample_id = db[:samples].insert(:name => "sample #{i}", :new_name_format => 1, :created_at => Time.now, :updated_at => Time.now)
      db[:uuids].insert(:resource_type => "Sample", :resource_id => sample_id, :external_id => uuid([1,0,0,0,i]))
      db[:study_samples].insert(:study_id => study_id, :sample_id => sample_id, :created_at => Time.now, :updated_at => Time.now)
    end

    db[:study_metadata].insert(:study_id => study_id, :study_name_abbreviation => "study1")
    db[:study_metadata].insert(:study_id => study_id, :study_name_abbreviation => "Study_1")
    db[:locations].insert(:name => "Sample logistics freezer")
  end
end
