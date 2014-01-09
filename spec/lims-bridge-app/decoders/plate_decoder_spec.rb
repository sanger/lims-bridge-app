require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/plate_decoder'

module Lims::BridgeApp::Decoders
  describe PlateDecoder do
    include_context "plate message"

    context "when creating a plate" do
      let(:result) { described_class.decode(plate_message) }

      it_behaves_like "decoding the resource", Lims::LaboratoryApp::Laboratory::Plate
      it_behaves_like "decoding the date"
      it_behaves_like "decoding the uuid"

      it "decodes the sample uuids" do
        result[:sample_uuids].should be_a(Hash)
        result[:sample_uuids].should == {"A1"=>["11111111-2222-3333-4444-555555555555"], "B2"=>["11111111-2222-3333-4444-666666666666", "11111111-2222-3333-4444-777777777777"]} 
      end

      it "decodes the plate" do
        result[:plate].number_of_rows.should == 8
        result[:plate].number_of_columns.should == 12

        result[:plate]["A1"].first.should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
        result[:plate]["A1"].first.type.should == "Sample type"
        result[:plate]["A1"].first.quantity.should == 1 

        result[:plate]["B2"][0].should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
        result[:plate]["B2"][0].type.should == "Sample type 2"
        result[:plate]["B2"][0].quantity.should == 2 

        result[:plate]["B2"][1].should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
        result[:plate]["B2"][1].type.should == "Sample type 3"
        result[:plate]["B2"][1].quantity.should == 3 
      end
    end

    context "when transfering a plate to another plate" do
      let(:result) { described_class.decode(transfer_plate_message) }

      it_behaves_like "decoding the date"

      it "decodes the 2 plates involved in the transfer" do
        result[:plates].should be_a(Array)
        result[:plates].size.should == 2  
        result[:plates][0].should be_a(Hash)
        result[:plates][0][:plate].should be_a(Lims::LaboratoryApp::Laboratory::Plate)
        result[:plates][0][:sample_uuids].should be_a(Hash) 
        result[:plates][0][:uuid].should_not be_nil 
      end

      it "decodes the transfer map" do
        result[:transfer_map].should == [{"source_uuid"=>"82805a60-5b7d-0131-978c-282066132de2", "source_location"=>"A1", "target_uuid"=>"8283b500-5b7d-0131-978c-282066132de2", "target_location"=>"B2"}] 
      end
    end
  end
end
