require 'lims-bridge-app/decoders/spec_helper'
require 'lims-bridge-app/decoders/messages_factory_helper'
require 'lims-bridge-app/decoders/tube_rack_decoder'

module Lims::BridgeApp::Decoders
  describe TubeRackDecoder do
    include_context "tube_rack message"

    context "when creating a tube rack" do
      let(:result) { described_class.decode(tube_rack_message) }

      it_behaves_like "decoding the resource", Lims::LaboratoryApp::Laboratory::Plate
      it_behaves_like "decoding the date"
      it_behaves_like "decoding the uuid"

      it "decodes the sample uuids" do
        result[:sample_uuids].should be_a(Hash)
        result[:sample_uuids].should == {"A1"=>["11111111-2222-3333-0000-111111111111"]} 
      end

      it "decodes the tube rack as a plate" do
        result[:plate].number_of_rows.should == 8
        result[:plate].number_of_columns.should == 12

        result[:plate]["A1"].first.should be_a(Lims::LaboratoryApp::Laboratory::Aliquot)
        result[:plate]["A1"].first.type.should == "DNA"
        result[:plate]["A1"].first.quantity.should == 10 
      end
    end


    context "when using the tube rack move action" do
      let(:result) { described_class.decode(tube_rack_move_message) }

      it_behaves_like "decoding the date"

      it "decodes the moves map" do
        result[:moves].should be_a(Array)
        result[:moves].size.should == 2
        result[:moves][0].should == {"source_uuid"=>"7cfb5530-5c43-0131-97bc-282066132de2", "source_location"=>"A1", "target_uuid"=>"7d2fdd60-5c43-0131-97bc-282066132de2", "target_location"=>"A2"}
        result[:moves][1].should == {"source_uuid"=>"7cfb5530-5c43-0131-97bc-282066132de2", "source_location"=>"B1", "target_uuid"=>"7d2fdd60-5c43-0131-97bc-282066132de2", "target_location"=>"B2"} 
      end
    end


    context "when using the tube rack transfer action" do
      let(:result) { described_class.decode(tube_rack_transfer_message) }

      it_behaves_like "decoding the date"

      it "decodes the 2 plates involved in the transfer" do
        result[:plates].should be_a(Array)
        result[:plates].size.should == 2  
        result[:plates].each do |plate_data|
          plate_data.should be_a(Hash)
          plate_data[:plate].should be_a(Lims::LaboratoryApp::Laboratory::Plate)
          plate_data[:sample_uuids].should be_a(Hash) 
          plate_data[:uuid].should_not be_nil 
        end
      end

      it "decodes the transfer map" do
        result[:transfer_map].should == [{"source_uuid"=>"ec507670-5c44-0131-97bc-282066132de2", "source_location"=>"A1", "target_uuid"=>"ec85e490-5c44-0131-97bc-282066132de2", "target_location"=>"B1"}] 
      end
    end
  end
end
