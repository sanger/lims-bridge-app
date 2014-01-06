require 'lims-bridge-app/spec_helper'

shared_examples_for "getting the right decoder" do |model|
  it "gets the right decoder" do
    Lims::BridgeApp::Decoders::BaseDecoder.send(:decoder_for, model).should == described_class
  end
end
