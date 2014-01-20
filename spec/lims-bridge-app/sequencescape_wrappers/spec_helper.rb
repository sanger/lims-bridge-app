require 'lims-bridge-app/spec_helper'

shared_context "sequencescape wrapper" do
  let(:settings) { YAML.load_file(File.join('config', 'bridge.yml'))["default"] }
  let(:wrapper) { described_class.new(settings) }
end

