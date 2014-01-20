require 'lims-bridge-app/spec_helper'

shared_context "sequencescape wrapper" do
  let(:settings) { YAML.load_file(File.join('config', 'bridge.yml'))["default"] }
  let(:wrapper) do 
    described_class.new(settings).tap do |w|
      w.date = Time.now.utc.to_s
    end
  end
end

shared_examples_for "changing table" do |table, quantity|
  it "updates the table #{table} by #{quantity} records" do
    expect do
      result
    end.to change { db[table.to_sym].count }.by(quantity)
  end
end
