require 'lims-bridge-app/spec_helper'

shared_examples_for "decoding the resource" do |resource_class|
  it "returns a hash" do
    result.should be_a(Hash)
  end

  it "decodes the resource" do
    result[result.keys.first].should be_a(resource_class)
  end
end

shared_examples_for "decoding the date" do
  it "decodes the date" do
    result[:date].should be_a(Time)
  end
end

shared_examples_for "decoding the uuid" do
  it "decodes the uuid" do
    result[:uuid].should_not be_nil
  end
end

