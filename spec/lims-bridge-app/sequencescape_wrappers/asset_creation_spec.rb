require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/message_handlers/factories'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/laboratory/aliquot'

module Lims::BridgeApp::MessageHandlers
  describe AssetCreationHandler do
    include_context "handler setup"
    include_context "prepare database"
    include_context "sequencescape sample study seeds"

    context "with a plate" do
      let(:resource) do
        {}.tap do |resource|
          resource[:plate] = Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12).tap do |plate|
            plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 10, :type => "DNA")
            plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 15, :type => "DNA")
            plate["A1"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 15, :type => "solvent")
            plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 20, :type => "solvent")
            plate["B2"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 25, :type => "RNA", :out_of_bounds => {:concentration => 4.0})
            plate["C3"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 30, :type => "NA")
          end
          resource[:uuid] = uuid([1,2,3,4,5])
          resource[:sample_uuids] = {
            "A1" => [uuid([1,0,0,0,1]),uuid([1,0,0,0,2])],
            "B2" => [uuid([1,0,0,0,3])],
            "C3" => [uuid([1,0,0,0,4])]
          }
          resource[:date] = Time.now
        end
      end

      before do
        bus.should_receive(:publish).with("11111111-2222-3333-4444-555555555555")
        metadata.should_receive(:ack)
      end

      it_behaves_like "changing table", :uuids, 1
      it_behaves_like "changing table", :assets, 97
      it_behaves_like "changing table", :container_associations, 96
      it_behaves_like "changing table", :aliquots, 4
      it_behaves_like "changing table", :location_associations, 1
      it_behaves_like "changing table", :requests, 3
      it_behaves_like "changing table", :well_attributes, 2

      it "creates the plate with a correct sti type"
      it "creates the wells with a correct sti type and association to the plate"
      it "sets the volume on the well attributes"
      it "creates aliquots"
    end
  end
end
