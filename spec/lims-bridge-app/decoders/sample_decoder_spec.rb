require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/sample_decoder'

module Lims::BridgeApp::Decoders
  describe SampleDecoder do
    include_context "sample message"

    context "when creating a sample" do
      let(:result) { described_class.decode(sample_message) }

      it_behaves_like "decoding the resource", Lims::ManagementApp::Sample
      it_behaves_like "decoding the date"
      it_behaves_like "decoding the uuid"

      it "decodes the sample" do
        result[:sample].state.should == "draft" 
        result[:sample].supplier_sample_name.should == "supplier sample name" 
        result[:sample].gender.should == "Male" 
        result[:sample].sanger_sample_id.should == "StudyX-506" 
        result[:sample].sample_type.should == "Cell Pellet" 
        result[:sample].scientific_name.should == "homo sapiens" 
        result[:sample].common_name.should == "man" 
        result[:sample].hmdmc_number.should == "123456" 
        result[:sample].ebi_accession_number.should == "accession number" 
        result[:sample].sample_source.should == "sample source" 
        result[:sample].mother.should == "mother"
        result[:sample].father.should == "father"
        result[:sample].sibling.should == "sibling"
        result[:sample].gc_content.should == "gc content"
        result[:sample].public_name.should == "public name"
        result[:sample].cohort.should == "cohort"
        result[:sample].storage_conditions.should == "storage conditions"
        result[:sample].dna.should be_a(Lims::ManagementApp::Sample::Dna) 
        result[:sample].dna.pre_amplified.should == false
        result[:sample].dna.date_of_sample_extraction.should be_a(DateTime)
        result[:sample].dna.extraction_method.should == "extraction method"
        result[:sample].dna.sample_purified.should == false 
        result[:sample].dna.concentration.should == 120 
        result[:sample].dna.concentration_determined_by_which_method.should == "method" 
        result[:sample].rna.should be_a(Lims::ManagementApp::Sample::Rna) 
        result[:sample].rna.pre_amplified.should == true
        result[:sample].rna.date_of_sample_extraction.should be_a(DateTime)
        result[:sample].rna.extraction_method.should == "extraction method"
        result[:sample].rna.sample_purified.should == true 
        result[:sample].rna.concentration.should == 120 
        result[:sample].rna.concentration_determined_by_which_method.should == "method" 
        result[:sample].cellular_material.should be_a(Lims::ManagementApp::Sample::CellularMaterial) 
        result[:sample].cellular_material.lysed.should == true 
        result[:sample].genotyping.should be_a(Lims::ManagementApp::Sample::Genotyping) 
        result[:sample].genotyping.country_of_origin.should == "england" 
        result[:sample].genotyping.geographical_region.should == "europe" 
        result[:sample].genotyping.ethnicity.should == "english" 
      end
    end


    # The json for bulk update samples and bulk delete samples is the same as bulk create samples
    context "when bulk creating samples" do
      let(:result) { described_class.decode(bulk_create_sample_message) }

      it_behaves_like "decoding the date"

      it "decodes the samples" do
        result[:samples].should be_a(Array)
        result[:samples].each do |sample|
          sample.should be_a(Hash)
          sample[:sample].should be_a(Lims::ManagementApp::Sample)
          sample[:uuid].should_not be_nil
        end
      end
    end
  end
end
