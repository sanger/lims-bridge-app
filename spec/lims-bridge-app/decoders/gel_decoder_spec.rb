require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/gel_decoder'

module Lims::BridgeApp::Decoders
  describe GelDecoder do
    include_context "gel message" 
    let(:result) { described_class.decode(message) }

    it_behaves_like "decoding the resource", Lims::LaboratoryApp::Laboratory::Plate
    it_behaves_like "decoding the date"
    it_behaves_like "decoding the uuid"

    it "decodes the sample uuids" do
      result[:sample_uuids].should be_a(Hash)
      result[:sample_uuids].should == {"A1"=>["11111111-0000-0000-0000-111111111111"], "B2"=>["11111111-0000-0000-0000-222222222222"], "C3"=>["11111111-0000-0000-0000-333333333333"]}
    end

    it "decodes the gel as a plate" do
      result[:plate].number_of_rows.should == 8
      result[:plate].number_of_columns.should == 12

      result[:plate]["A1"].first.should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
      result[:plate]["A1"].first.type.should == "DNA"
      result[:plate]["A1"].first.quantity.should == 10 

      result[:plate]["B2"][0].should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
      result[:plate]["B2"][0].type.should == "RNA"
      result[:plate]["B2"][0].quantity.should == 20 

      result[:plate]["B2"][1].should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
      result[:plate]["B2"][1].type.should == "solvent"
      result[:plate]["B2"][1].quantity.should == 20 

      result[:plate]["C3"][0].should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
      result[:plate]["C3"][0].type.should == "DNA"
      result[:plate]["C3"][0].quantity.should == 30 
      result[:plate]["C3"][0].out_of_bounds.should == {"concentration" => 33.33} 
    end
  end
end
