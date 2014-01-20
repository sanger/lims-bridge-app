require 'lims-bridge-app/sequencescape_wrappers/spec_helper'
require 'lims-bridge-app/sequencescape_wrapper'

module Lims::BridgeApp
  describe SequencescapeWrapper do
    include_context "sequencescape wrapper"
    include_context "prepare database"

    context "when updating aliquots" do
      pending
    end
  end
end
