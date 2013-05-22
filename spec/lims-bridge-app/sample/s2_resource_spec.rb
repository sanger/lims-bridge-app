require 'lims-bridge-app/sample/spec_helper'
require 'lims-bridge-app/sample/json_decoder'
require 'lims-bridge-app/s2_resource'

module Lims::BridgeApp::SampleManagement
  describe "S2 resource mapping" do
    before do
      @convertor = Class.new do
        include Lims::BridgeApp::SampleManagement::JsonDecoder
        include Lims::BridgeApp::S2Resource
      end.new
    end

    let(:result) { @convertor.s2_resource(payload) }

    shared_examples_for "a sample" do
      it "returns a hash" do
        result.should be_a(Hash)
      end

      it "returns a sample resource" do
        result[:sample].should be_a(Lims::ManagementApp::Sample)
      end

      it "returns the sample uuid" do
        result[:uuid].should_not be_nil
        result[:uuid].should be_a(String)
      end

      it "returns the date" do
        result[:date].should_not be_nil
        result[:date].should be_a(String)
      end
    end

    context "sample message" do
      let(:payload) { '{"sample":{"actions":{"read":"http://localhost:9292/92419010-a4fd-0130-4de7-282066132de2","create":"http://localhost:9292/92419010-a4fd-0130-4de7-282066132de2","update":"http://localhost:9292/92419010-a4fd-0130-4de7-282066132de2","delete":"http://localhost:9292/92419010-a4fd-0130-4de7-282066132de2"},"uuid":"92419010-a4fd-0130-4de7-282066132de2","supplier_sample_name":"supplier sample name","gender":"Male","sanger_sample_id":"S2-a78412a01473451fbf556df6ab12d258","sample_type":"RNA","taxon_id":9606,"scientific_name":"homo sapiens","common_name":"man","hmdmc_number":"123456","ebi_accession_number":"accession number","sample_source":"sample source","mother":"mother","father":"father","sibling":"sibling","gc_content":"gc content","public_name":"public name","cohort":"cohort","storage_conditions":"storage conditions","volume":100,"date_of_sample_collection":"2013-06-24T00:00:00+01:00","is_sample_a_control":true,"is_re_submitted_sample":false,"dna":{"pre_amplified":false,"date_of_sample_extraction":"2013-06-02T00:00:00+00:00","extraction_method":"extraction method","concentration":120,"sample_purified":false,"concentration_determined_by_which_method":"method"},"cellular_material":{"lysed":false},"genotyping":{"country_of_origin":"england","geographical_region":"europe","ethnicity":"english"}},"action":"create","date":"2013-05-22 11:06:27 UTC","user":"user"}' }
      it_behaves_like "a sample"
    end

    context "bulk create sample message" do
      pending
    end

    context "bulk update sample message" do
      pending
    end

    context "bulk delete sample message" do
      pending
    end
  end
end
