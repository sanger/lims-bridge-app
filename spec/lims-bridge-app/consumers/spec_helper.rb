require 'lims-bridge-app/spec_helper'

module Lims::BridgeApp
  shared_context "plate management consumer" do
    let(:consumer) do
      amqp_settings = YAML.load_file(File.join('config','amqp.yml'))["test"]
      bridge_settings = YAML.load_file(File.join('config','bridge.yml'))
      described_class.new(amqp_settings, bridge_settings)
    end
  end

  shared_examples_for "routing message" do |routing_key, handler_class|
    let(:metadata) { mock(:metadata).tap { |m|
      m.stub(:routing_key).and_return(routing_key)
    }}

    it "routes the message to the correct handler" do
      route = consumer.send(:route_for, routing_key) 
      MessageHandlers.handler_for(route).should == handler_class
    end

    it "calls the handler" do
      handler_class.any_instance.should_receive(:call)
      consumer.send(:route_message, metadata, mock(:resource)) 
    end
  end
end
