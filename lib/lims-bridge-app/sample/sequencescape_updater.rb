require 'lims-bridge-app/sample/sequencescape_mapper'
require 'sequel'
require 'sequel/adapters/mysql'
require 'rubygems'
require 'ruby-debug/debugger'

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

      def dispatch_s2_sample_in_sequencescape(sample, sample_uuid)
        db.transaction do
          components = [:dna, :rna].keep_if { |c| sample.send(c) }
          if components.empty?
            sample_id = create_sample_record(sample)
            create_uuid_record(sample_id, sample_uuid)
          else
            components.each do |c|
              sample_id = create_sample_record(sample, c)
              create_uuid_record(sample_id, sample_uuid)
            end
          end
        end
      end

      def create_sample_record(sample, component = nil)
        sample_values = prepare_data(sample, :samples)
        sample_id = db[:samples].insert(sample_values)

        sample_metadata_values = prepare_data(sample, :sample_metadata, component)
        sample_metadata_values.merge!({:sample_id => sample_id})
        db[:sample_metadata].insert(sample_metadata_values)
        sample_id
      end

      def create_uuid_record(sample_id, sample_uuid)
        db[:uuids].insert({
          :resource_type => 'Sample',
          :resource_id => sample_id,
          :external_id => sample_uuid
        })
      end

      def prepare_data(sample, table, component = nil)
        map = MAPPING[table]
        {}.tap do |h|
          map.each do |s_attribute, s2_attribute|
            if component && s2_attribute =~ /__component__/
              next unless sample.send(component)
              h[s_attribute] = sample.send(component).send(s2_attributes.scan(/__component__(.*)/).last.first) 
            else
              h[s_attribute] = sample.send(s2_attribute) if s2_attribute && sample.respond_to?(s2_attribute) 
            end
          end
        end
      end
    end
  end
end
