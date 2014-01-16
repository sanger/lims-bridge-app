require 'lims-bridge-app/sequencescape_model'
require 'lims-bridge-app/sequencescape_wrappers/asset_creation'
require 'lims-bridge-app/sequencescape_wrappers/gel_score_update'
require 'lims-bridge-app/sequencescape_wrappers/helper'

module Lims::BridgeApp
  class SequencescapeWrapper
    include SequencescapeModel
    include SequencescapeWrapper::Helper
    include SequencescapeWrapper::AssetCreation
    include SequencescapeWrapper::GelScoreUpdate

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
