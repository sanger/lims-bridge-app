require 'spec_helper'
require 'sequel'

shared_context "test database" do
  let(:db) { Sequel.sqlite 'test.db' }
  after(:each) do
    seed_tables = ["maps", "uuids"]
    db.tables.each do |table|
      db[table.to_sym].delete unless seed_tables.include?(table.to_s)
    end
    db[:uuids].where{id > 6}.delete
  end
end
