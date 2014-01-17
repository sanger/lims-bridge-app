require 'lims-bridge-app/sequencescape_model'
require 'lims-bridge-app/sequencescape_wrappers/asset_creation'
require 'lims-bridge-app/sequencescape_wrappers/asset_deletion'
require 'lims-bridge-app/sequencescape_wrappers/gel_score_update'
require 'lims-bridge-app/sequencescape_wrappers/barcode'
require 'lims-bridge-app/sequencescape_wrappers/plate_purpose'
require 'lims-bridge-app/sequencescape_wrappers/transfer'
require 'lims-bridge-app/sequencescape_wrappers/helper'

module Lims::BridgeApp
  class SequencescapeWrapper
    include SequencescapeModel
    include SequencescapeWrapper::Helper
    include SequencescapeWrapper::AssetCreation
    include SequencescapeWrapper::AssetDeletion
    include SequencescapeWrapper::GelScoreUpdate
    include SequencescapeWrapper::Barcode
    include SequencescapeWrapper::PlatePurpose
    include SequencescapeWrapper::Transfer

    attr_accessor :date
    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end

    def call(&block)
      SequencescapeDB.transaction do
        block.call
      end
    end
  end
end
