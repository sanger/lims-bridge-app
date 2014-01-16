require 'spec_helper'
require 'sequel'

unless defined?(SequencescapeDB)
  sequencescape_db_settings = YAML.load_file(File.join('config','database.yml'))
  SequencescapeDB = Sequel.connect(sequencescape_db_settings["test"])
end

def uuid(pattern=[])
  if pattern.empty?
    "11111111-2222-3333-4444-555555555555"
  else
    uuid_v4 = [8,4,4,4,12]
    [].tap do |uuid|
      pattern.zip(uuid_v4).each do |digit, n|
        uuid << digit.to_s * n 
      end
    end.join("-")
  end
end

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
