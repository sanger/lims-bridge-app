require 'lims-bridge-app/spec_helper'

shared_context "handler setup" do
  let(:bus) { mock(:bus) }
  let(:log) { mock(:log).tap { |l| 
    l.stub(:info)
    l.stub(:debug)
    l.stub(:error)
  }}
  let(:metadata) { mock(:metadata) }
  let(:settings) { YAML.load_file(File.join('config','bridge.yml'))["default"] }
  let(:handler) { described_class.new(bus, log, metadata, resource, settings) }
  let(:sequencescape) { handler.send(:sequencescape) }
end
