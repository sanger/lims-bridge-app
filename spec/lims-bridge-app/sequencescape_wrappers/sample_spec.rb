require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'
require 'lims-management-app/sample/sample'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    let(:common_parameters) {{
      :hmdmc_number => "test", :supplier_sample_name => "test", :common_name => "human",
      :ebi_accession_number => "test", :sample_source => "test", :mother => "test", :father => "test",
      :sibling => "test", :gc_content => "test", :public_name => "test", :cohort => "test", 
      :storage_conditions => "test", :taxon_id => 9606, :scientific_name => "Homo sapiens",
      :gender => "male", :sample_type => "RNA", :volume => 1, :date_of_sample_collection => DateTime.now, 
      :is_sample_a_control => true, :is_re_submitted_sample => false, :sanger_sample_id => "sanger sample id"
    }}
    let(:dna_parameters) {{
      :pre_amplified => true,
      :date_of_sample_extraction => DateTime.now,
      :extraction_method => "method",
      :concentration => 100,
      :sample_purified => true,
      :concentration_determined_by_which_method => "method"
    }}
    let(:cellular_material_parameters) {{
      :lysed => true,
      :donor_id => "donor id"
    }}
    let(:genotyping_parameters) {{
      :country_of_origin => "United Kingdom",
      :geographical_region => "Cambridgeshire",
      :ethnicity => "english"
    }}
    let(:sample_uuid) { uuid [1,2,3,4,5] }
    let(:sample) do
      Lims::ManagementApp::Sample.new(common_parameters).tap do |s|
        s.dna = Lims::ManagementApp::Sample::Dna.new(dna_parameters)
        s.cellular_material = Lims::ManagementApp::Sample::CellularMaterial.new(cellular_material_parameters)
        s.genotyping = Lims::ManagementApp::Sample::Genotyping.new(genotyping_parameters)
      end
    end

    context "when creating a sample" do
      let(:result) { wrapper.create_sample(sample) }

      it_behaves_like "changing table", :samples, 1
      it_behaves_like "changing table", :sample_metadata, 1

      it "saves the sample" do
        SequencescapeModel::Sample[:id => result].tap do |s|
          s.sanger_sample_id.should == sample.sanger_sample_id
          s.name.should == sample.sanger_sample_id
          s.control.should == (sample.is_sample_a_control ? 1 : 0)
          s.created_at.to_s.should == date
          s.updated_at.to_s.should == date
        end
      end

      it "saves the sample metadata" do
        SequencescapeModel::SampleMetadata[:sample_id => result].tap do |sm|
          sm.gc_content.should == sample.gc_content
          sm.donor_id.should == sample.cellular_material.donor_id
          sm.gender.should == sample.gender
          sm.country_of_origin.should == sample.genotyping.country_of_origin
          sm.geographical_region.should == sample.genotyping.geographical_region
          sm.ethnicity.should == sample.genotyping.ethnicity
          sm.dna_source.should == sample.sample_source
          sm.volume.should == sample.volume.to_s
          sm.mother.should == sample.mother
          sm.father.should == sample.father
          sm.sample_public_name.should == sample.public_name
          sm.sample_common_name.should == sample.scientific_name
          sm.sample_taxon_id.should == sample.taxon_id
          sm.sample_ebi_accession_number.should == sample.ebi_accession_number
          sm.sibling.should == sample.sibling
          sm.is_resubmitted.should == (sample.is_re_submitted_sample ? 1 : 0)
          sm.date_of_sample_collection.should == sample.date_of_sample_collection.to_s
          sm.date_of_sample_extraction.should == sample.dna.date_of_sample_extraction.to_s
          sm.sample_extraction_method.should == sample.dna.extraction_method
          sm.sample_purified.should == sample.dna.sample_purified.to_s
          sm.concentration.should == sample.dna.concentration.to_s
          sm.concentration_determined_by.should == sample.dna.concentration_determined_by_which_method
          sm.sample_type.should == sample.sample_type
          sm.sample_storage_conditions.should == sample.storage_conditions
          sm.supplier_name.should == sample.supplier_sample_name
          sm.created_at.to_s.should == date
          sm.updated_at.to_s.should == date
        end
      end
    end


    context "when updating a sample" do
      let(:result) { wrapper.update_sample(sample, sample_uuid) }

      context "with a known sample" do
        let(:sample_id) { wrapper.asset_id_by_uuid(sample_uuid) }

        before do 
          sample_id = wrapper.create_sample(sample)
          wrapper.create_uuid(settings["sample_type"], sample_id, sample_uuid) 
        end

        it_behaves_like "changing table", :samples, 0
        it_behaves_like "changing table", :sample_metadata, 0

        it "updates the sample" do
          result
          SequencescapeModel::Sample[:id => sample_id].tap do |s|
            s.updated_at.to_s.should == date
          end
        end

        it "updates the sample metadata" do
          result
          SequencescapeModel::SampleMetadata[:sample_id => sample_id].tap do |sm|
            sm.updated_at.to_s.should == date
          end
        end
      end

      context "with an unknown sample" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end


    context "when deleting a sample" do
      let(:result) { wrapper.delete_sample(sample_uuid) }

      context "with a known sample" do
        before do
          sample_id = wrapper.create_sample(sample)
          wrapper.create_uuid(settings["sample_type"], sample_id, sample_uuid)
        end

        it_behaves_like "changing table", :samples, -1
        it_behaves_like "changing table", :sample_metadata, -1
        it_behaves_like "changing table", :uuids, -1
      end

      context "with an unknown sample" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::AssetNotFound)
        end
      end
    end

    
    context "when creating a study sample" do
      let(:study_abbreviation) { "Study abbreviation" }
      let(:sample_id) { wrapper.create_sample(sample) }
      let(:result) { wrapper.create_study_sample(sample_id, study_abbreviation) }

      context "with studies found" do
        let!(:study_metadata_id_1) { SequencescapeModel::StudyMetadata.insert(:study_name_abbreviation => "study abbreviation", :study_id => 1) }
        let!(:study_metadata_id_2) { SequencescapeModel::StudyMetadata.insert(:study_name_abbreviation => "STUDY ABBREVIATION", :study_id => 2) }

        it_behaves_like "changing table", :study_samples, 2
        it_behaves_like "changing table", :uuids, 2

        it "saves the study samples" do
          result

          SequencescapeModel::StudySample[:study_id => study_metadata_id_1].tap do |ss|
            ss.sample_id.should == sample_id
          end

          SequencescapeModel::StudySample[:study_id => study_metadata_id_2].tap do |ss|
            ss.sample_id.should == sample_id
          end
        end

        it "returns an array of uuids" do
          result.should be_a(Array)
          result.size.should == 2
          result.each do |uuid|
            SequencescapeModel::Uuid[:external_id => uuid].should_not be_nil
          end
        end
      end

      context "with no studies found" do
        it "raises an error" do
          expect do
            result
          end.to raise_error(SequencescapeWrapper::UnknownStudy)
        end
      end
    end
  end
end
