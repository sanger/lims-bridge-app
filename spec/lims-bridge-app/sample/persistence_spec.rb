require 'lims-bridge-app/sample/spec_helper'
require 'lims-bridge-app/sample/sequencescape_updater'

module Lims::BridgeApp::SampleManagement
  describe "Persistence on Sequencescape database" do
    include_context "test database"

    shared_examples_for "updating table" do |table, quantity|
      it "update the table #{table} by #{quantity} record" do
        expect do
          updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, method)
        end.to change { db[table.to_sym].count }.by(quantity)
      end
    end

    def update_parameters(parameters)
      parameters.mash do |k,v|
        case v
        when DateTime then [k, DateTime.now.to_s]
        when TrueClass then [k, false]
        when FalseClass then [k, true]
        when Fixnum then k.to_s == "taxon_id" ? [k, v] : [k, v+1]
        when Hash then [k, update_parameters(v)]
        else 
          case k
          when :gender then [k, "Hermaphrodite"]
          when :sample_type then [k, "Blood"]
          when :common_name then [k, v]
          when :scientific_name then [k, v]
          else [k, "new #{v}"]
          end
        end
      end
    end

    let(:db_settings) { YAML.load_file(File.join('config', 'database.yml'))['test'] }
    let!(:updater) do
      Class.new { include SequencescapeUpdater }.new.tap do |o|
        o.sequencescape_db_setup(db_settings)
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
      s
    end

    context "create sample" do
      let(:method) { "create" }
      it_behaves_like "updating table", :samples, 1
      it_behaves_like "updating table", :sample_metadata, 1
      it_behaves_like "updating table", :uuids, 1
    end

   context "update sample" do
     let(:method) { "update" }
     before do
       updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, "create")
     end

     it_behaves_like "updating table", :samples, 0
     it_behaves_like "updating table", :sample_metadata, 0
     it_behaves_like "updating table", :uuids, 0
   end

   context "delete sample" do
     let(:method) { "delete" }
     before(:each) do
       updater.dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, "create")
     end

     it_behaves_like "updating table", :samples, -1
     it_behaves_like "updating table", :sample_metadata, -1
     it_behaves_like "updating table", :uuids, -1
   end
  end
end
