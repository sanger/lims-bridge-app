require 'lims-bridge-app/sample_management/spec_helper'
require 'lims-bridge-app/sample_management/sequencescape_updater'

module Lims::BridgeApp::SampleManagement
  describe "Persistence on Sequencescape database" do
    include_context "prepare database"

    shared_examples_for "updating table" do |table, quantity|
      it "updates the table #{table} by #{quantity} record" do
        expect do
          updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, method)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    let(:db_settings) { YAML.load_file(File.join('config', 'database.yml'))['test'] }
    let(:bridge_settings) { YAML.load_file(File.join('config', 'bridge.yml'))['default']['sample_management'] }
    let(:bus) { mock(:bus).tap { |n| n.stub(:publish) }}
    let!(:updater) do
      Class.new do
        include SequencescapeUpdater
        attr_accessor :bus
        attr_accessor :db
        attr_accessor :settings
      end.new.tap do |o|
        o.db = Sequel.connect(db_settings)
        o.bus = bus 
        o.settings = bridge_settings
      end
    end

    let(:sample_uuid) { "11111111-2222-3333-4444-555555555555" }
    let(:date) { DateTime.now.to_s }
    let!(:sample) do
      s = Lims::ManagementApp::Sample.new({
        :hmdmc_number => "test", :supplier_sample_name => "test", :common_name => "human",
        :ebi_accession_number => "test", :sample_source => "test", :mother => "test", :father => "test",
        :sibling => "test", :gc_content => "test", :public_name => "test", :cohort => "test", 
        :storage_conditions => "test", :taxon_id => 9606, :scientific_name => "Homo sapiens",
        :gender => "male", :sample_type => "RNA", :volume => 1, :date_of_sample_collection => DateTime.now, 
        :is_sample_a_control => true, :is_re_submitted_sample => false
      })
      s.dna = { 
        :pre_amplified => true,
        :date_of_sample_extraction => DateTime.now,
        :extraction_method => "method",
        :concentration => 100,
        :sample_purified => true,
        :concentration_determined_by_which_method => "method"
      }
      s.cellular_material = {:lysed => true}
      s.genotyping = {
        :country_of_origin => "United Kingdom",
        :geographical_region => "Cambridgeshire",
        :ethnicity => "english"
      }
      s.sanger_sample_id = "StudyX-1"
      s
    end

    context "create sample" do
      let(:method) { "create" }

      context "valid creation" do
        it_behaves_like "updating table", :samples, 1
        it_behaves_like "updating table", :sample_metadata, 1
        it_behaves_like "updating table", :uuids, 3
        it_behaves_like "updating table", :study_samples, 2
      end

      context "invalid creation" do
        let(:sample_with_unknown_study) { sample.tap { |s| s.sanger_sample_id = "dummy-1" } }

        it "raises an error if no study can be found to link to the sample" do
          expect do
            updater.dispatch_s2_sample_in_sequencescape(sample_with_unknown_study, sample_uuid, date, method)   
          end.to raise_error(UnknownStudy)
        end
      end
    end

   context "update sample" do
     let(:method) { "update" }

     context "valid update" do
       before { updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, "create") } 
       it_behaves_like "updating table", :samples, 0
       it_behaves_like "updating table", :sample_metadata, 0
       it_behaves_like "updating table", :uuids, 0
     end

     context "invalid update" do
       it "raises an error if the sample to update cannot be found" do
         expect do
           updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, method)   
         end.to raise_error(UnknownSample)
       end
     end
   end

   context "delete sample" do
     let(:method) { "delete" }

     context "valid delete" do
       before(:each) do
         updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, "create")
       end

       it_behaves_like "updating table", :samples, -1
       it_behaves_like "updating table", :sample_metadata, -1
       it_behaves_like "updating table", :uuids, -1
     end

     context "invalid delete" do
       it "raises an error if the sample to delete cannot be found" do
         expect do
           updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, method)   
         end.to raise_error(UnknownSample)
       end
     end
   end
  end
end
