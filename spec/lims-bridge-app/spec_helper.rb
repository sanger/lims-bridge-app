require 'spec_helper'
require 'sequel'

shared_context "test database" do
  let(:db) { Sequel.sqlite 'test.db' }
  after(:each) do
    db.tables.each do |table|
      db[table.to_sym].delete
    end
  end
end
