require 'sequel'
require 'yaml'

Sequel.default_timezone = :utc

module Lims::BridgeApp
  module SequencescapeModel
    unless defined?(SequencescapeDB)
      #env = ENV["LIMS_BRIDGE_APP_ENV"]
      env = "development"
      sequencescape_db_settings = YAML.load_file(File.join('config','database.yml'))
      SequencescapeDB = Sequel.connect(sequencescape_db_settings[env])
    end

    module SetupSequencescapeDefaultModel
      def self.included(klass)
        SequencescapeDB.tables.each do |table|
          SequencescapeModel.class_eval %Q{
            class #{table.capitalize} < Sequel::Model
            end
          }
        end
      end
    end
    include SetupSequencescapeDefaultModel
  end
end
