require 'lims-bridge-app/plate_management/persistence/spec_helper'
require 'lims-laboratory-app/laboratory/plate'
require 'lims-bridge-app/plate_management/message_handlers/spec_helper'
require 'lims-bridge-app/plate_management/message_handlers/transfer_handler'

module Lims::BridgeApp::PlateManagement::MessageHandler
  describe TransferHandler do
    include_context "prepare database for plate management"
    include_context "updater"
    include_context "source and target plate"
    include_context "plate settings"

    let(:bus) { mock(:bus).tap { |b| b.stub(:publish) }}
    let(:metadata) { mock(:metadata).tap { |b| b.stub(:ack); b.stub(:reject) }}
    let(:log) { mock(:log).tap { |b| b.stub(:info) }}
    let(:handler) { TransferHandler.new(db, bus, log, metadata,
      {:plates => plates, :transfer_map => transfer_map},
      settings) }
    let(:date) { Time.now }

    shared_examples_for "adding asset links" do |quantity|
      it "insert records into asset_links table" do
        expect do
          handler.send(:add_asset_links, transfer_map, date)
        end.to change { db[:asset_links].count }.by(quantity)
      end
    end

    before do 
      updater.create_plate_in_sequencescape(source_plate, source_plate_uuid, Time.now, sample_uuids)
      updater.create_plate_in_sequencescape(target_plate, target_plate_uuid, Time.now, {})
    end

    context "Transfer samples from a source plate to a target plate" do

      let(:plates) do
        [ { :plate        => source_plate,
            :uuid         => source_plate_uuid,
            :sample_uuids => sample_uuids,
            :date         => date},
          { :plate        => target_plate,
            :uuid         => target_plate_uuid,
            :sample_uuids => {},
            :date         => date}
          ]
      end
      let(:transfer_map) {
        [ { "source_uuid"      => source_plate_uuid,
            "source_location"  => "A1",
            "target_uuid"      => target_plate_uuid,
            "target_location"  => "A1"},
          { "source_uuid"      => source_plate_uuid,
            "source_location"  => "B2",
            "target_uuid"      => target_plate_uuid,
            "target_location"  => "B2"},
          { "source_uuid"      => source_plate_uuid,
            "source_location"  => "C3",
            "target_uuid"      => target_plate_uuid,
            "target_location"  => "C3"},
          { "source_uuid"      => source_plate_uuid,
            "source_location"  => "D4",
            "target_uuid"      => target_plate_uuid,
            "target_location"  => "D4"}
        ]
      }

      it_behaves_like "adding asset links", 1
    end
  end
end
