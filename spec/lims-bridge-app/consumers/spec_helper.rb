require 'lims-bridge-app/spec_helper'

module Lims::BridgeApp
  shared_context "consumer" do
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
      resource = mock(:resource).tap { |r| r.stub(:[]) }
      consumer.send(:route_message, metadata, resource) 
    end
  end

  shared_examples_for "failing to route message" do
    context "fail to route messages" do
      it "doesn't find the route from the routing key" do
        expect do
          consumer.send(:route_for, "dummy")
        end.to raise_error(BaseConsumer::NoRouteFound)
      end

      it "doesn't find the handler from the route" do
        expect do
          MessageHandlers.handler_for("dummy") 
        end.to raise_error(MessageHandlers::UndefinedHandler)
      end
    end
  end
end
