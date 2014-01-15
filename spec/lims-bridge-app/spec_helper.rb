require 'spec_helper'
require 'sequel'

shared_context "test database" do
  let(:db) { Sequel.sqlite 'test.db' }
end

shared_context "prepare database" do
  include_context "test database"
  after(:each) do
    seed_tables = ["maps"]
    db.tables.each do |table|
      db[table.to_sym].delete unless seed_tables.include?(table.to_s)
    end
  end
end

shared_context "seed database" do
  include_context "test database"
end
