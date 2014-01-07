require 'lims-bridge-app/plate_management/persistence/spec_helper'
require 'lims-bridge-app/plate_management/persistence/persistence_shared'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-laboratory-app/laboratory/gel'
require 'lims-quality-app/gel-image/gel_image'

module Lims::BridgeApp::PlateManagement
  describe "Updating gel scores" do
    include_context "prepare database for plate management"
    include_context "updater"

    let(:number_of_rows) { 8 }
    let(:number_of_columns) { 12 }

    let(:stock_plate) do
      Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows,  :number_of_columns => number_of_columns).tap do |plate|
        (1..4).to_a.each do |i|
          plate["A#{i}"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 100)
          plate["A#{i}"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 100, :type => "solvent")
        end
      end
    end

    let(:working_dilution_plate) do
      Lims::LaboratoryApp::Laboratory::Plate.new(:number_of_rows => number_of_rows,  :number_of_columns => number_of_columns).tap do |plate|
        (1..4).to_a.each do |i|
          plate["B#{i}"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 50)
          plate["B#{i}"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 50, :type => "solvent")
        end
      end
    end

    let(:gel) do
      Lims::LaboratoryApp::Laboratory::Gel.new(:number_of_rows => number_of_rows,  :number_of_columns => number_of_columns).tap do |gel|
        (1..4).to_a.each do |i|
          gel["C#{i}"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 10)
          gel["C#{i}"] << Lims::LaboratoryApp::Laboratory::Aliquot.new(:quantity => 10, :type => "solvent")
        end
      end
    end

    let(:stock_well_ids) do
      stock_plate_id = updater.plate_id_by_uuid("11111111-1111-1111-1111-111111111111")
      [1,2,3,4].map do |i|
        updater.well_id_by_location(stock_plate_id, "A#{i}")
      end
    end

    before do
      updater.create_plate_in_sequencescape(stock_plate, "11111111-1111-1111-1111-111111111111", Time.now, {
        "A1" => ["11111111-0000-0000-0000-111111111111"],
        "A2" => ["11111111-0000-0000-0000-222222222222"],
        "A3" => ["11111111-0000-0000-0000-333333333333"],
        "A4" => ["11111111-0000-0000-0000-444444444444"]
      })
      updater.create_plate_in_sequencescape(working_dilution_plate, "11111111-1111-1111-1111-222222222222", Time.now, {
        "B1" => ["11111111-0000-0000-0000-111111111111"],
        "B2" => ["11111111-0000-0000-0000-222222222222"],
        "B3" => ["11111111-0000-0000-0000-333333333333"],
        "B4" => ["11111111-0000-0000-0000-444444444444"]
      })
      updater.create_plate_in_sequencescape(gel, "11111111-1111-1111-1111-333333333333", Time.now, {
        "C1" => ["11111111-0000-0000-0000-111111111111"],
        "C2" => ["11111111-0000-0000-0000-222222222222"],
        "C3" => ["11111111-0000-0000-0000-333333333333"],
        "C4" => ["11111111-0000-0000-0000-444444444444"]
      })

      working_dilution_plate_id = updater.plate_id_by_uuid("11111111-1111-1111-1111-222222222222")
      gel_id = updater.plate_id_by_uuid("11111111-1111-1111-1111-333333333333")

      wd_well_ids = [1,2,3,4].map { |i| updater.well_id_by_location(working_dilution_plate_id, "B#{i}") }
      gel_well_ids = [1,2,3,4].map { |i| updater.well_id_by_location(gel_id, "C#{i}") }

      stock_well_ids.zip(wd_well_ids).each do |well|
        db[:requests].insert({
          :state => "passed", 
          :request_type_id => 22,
          :asset_id => well[0], 
          :target_asset_id => well[1],
          :sti_type => "TransferRequest"
        })
      end

      wd_well_ids.zip(gel_well_ids).each do |well|
        db[:requests].insert({
          :state => "passed", 
          :request_type_id => 22,
          :asset_id => well[0], 
          :target_asset_id => well[1],
          :sti_type => "TransferRequest"
        })
      end
    end


    context "update gel score of the stock plate well attribute" do
      before do
        updater.update_gel_scores(gel_image)
      end

      let(:stock_wells) { db[:well_attributes].where(:well_id => stock_well_ids).all }
      let(:gel_image) do
        Lims::QualityApp::GelImage.new(
          :gel_uuid => "11111111-1111-1111-1111-333333333333",
          :scores => { 
            "C1" => "pass",
            "C2" => "fail",
            "C3" => "degraded",
            "C4" => "partially degraded"
          }
        )
      end


      it "changes the score of stock plate well A1" do
        stock_wells[0][:gel_pass].should == "OK"
        stock_wells[1][:gel_pass].should == "fail"
        stock_wells[2][:gel_pass].should == "Degraded"
        stock_wells[3][:gel_pass].should == "Partially degraded"
      end
    end
  end
end
