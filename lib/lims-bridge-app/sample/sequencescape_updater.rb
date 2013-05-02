require 'lims-bridge-app/sample/sequencescape_mapper'
require 'sequel'
require 'sequel/adapters/mysql'

module Lims::BridgeApp
  module SampleManagement
    module SequencescapeUpdater
      include SequencescapeMapper

      def self.included(klass)
        klass.class_eval do
          include Virtus
          include Aequitas
          attribute :mysql_settings, Hash, :required => true, :writer => :private, :reader => :private
          attribute :db, Sequel::MySQL::Database, :required => true, :writer => :private, :reader => :private
        end
      end

      # Setup the Sequencescape database connection
      # @param [Hash] MySQL settings
      def sequencescape_db_setup(settings = {})
        @mysql_settings = settings
        @db = Sequel.connect(:adapter => mysql_settings['adapter'],
                             :host => mysql_settings['host'],
                             :user => mysql_settings['user'],
                             :password => mysql_settings['password'],
                             :database => mysql_settings['database'])
      end 

      def create_sample_in_sequencescape(sample, sample_uuid)
        db.transaction do
          [:dna, :rna].each do |component|
            if sample.send(component)
              sample_values = prepare_data_for_sequencescape(sample, :samples)
              sample_id = db[:samples].insert(sample_values)

              sample_metadata_values = prepare_data_for_sequencescape(sample, :sample_metadata, component)
              sample_metadata_values.merge!({:sample_id => sample_id})
              db[:sample_metadata].insert(sample_metadata_values)
            end
          end
        end
      end

      def prepare_data_for_sequencescape(sample, table, component = nil)
        map = MAPPING[table]
        {}.tap do |h|
          map.each do |s_attribute, s2_attribute|
            if s2_attribute =~ /__component__/
              h[s_attribute] = sample.send(component).send(s2_attributes.scan(/__component__(.*)/).last.first) 
            else
              h[s_attribute] = sample.send(s2_attribute) 
            end
          end
        end
      end
    end
  end
end
