require 'lims-bridge-app/plate_management/spec_helper'

shared_context "plate settings" do
  let(:settings) { YAML.load_file(File.join('config', 'bridge.yml'))['default']['plate_management'] }
end

