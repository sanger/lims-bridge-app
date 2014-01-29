require 'sequel'
require 'yaml'

Sequel.default_timezone = :utc

module Lims::BridgeApp
  module SequencescapeModel
    unless defined?(SequencescapeDB)
      env = ENV["LIMS_BRIDGE_APP_ENV"]
      sequencescape_db_settings = YAML.load_file(File.join('config','database.yml'))
      SequencescapeDB = Sequel.connect(sequencescape_db_settings[env])
    end

    module SetupSequencescapeDefaultModel
      def self.included(klass)
        SequencescapeDB.tables.each do |table|
          table_to_class_name  = table.to_s.capitalize.gsub(/_./) {|p| p[1].upcase}
          singular_model_class_name = table_to_class_name.tap { |str| str.chop! if str =~ /s$/ }
          SequencescapeModel.class_eval %Q{
            class #{singular_model_class_name} < Sequel::Model
              def self.get_or_create(criteria={})
                self[criteria] || self.new(criteria)
              end
            end
          }
        end
      end
    end

    module SetupSequencescapeModelDataset
      def self.included(klass)
        SequencescapeModel::SampleMetadata.set_dataset :sample_metadata
        SequencescapeModel::StudyMetadata.set_dataset :study_metadata
      end
    end

    include SetupSequencescapeDefaultModel
    include SetupSequencescapeModelDataset
  end
end
