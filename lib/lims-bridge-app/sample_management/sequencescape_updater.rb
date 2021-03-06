require 'lims-management-app/sample/sample'
require 'lims-bridge-app/sample_management/sequencescape_mapper'
require 'sequel'
require 'sequel/adapters/mysql2'
require 'securerandom'

module Lims::BridgeApp
  module SampleManagement

    UnknownSample = Class.new(StandardError)
    UnknownStudy = Class.new(StandardError)

    module SequencescapeUpdater
      include SequencescapeMapper

      # @param [Lims::ManagementApp::Sample] sample
      # @param [String] sample_uuid
      # @param [Time] date
      # @param [String] method
      def dispatch_s2_sample_in_sequencescape(sample, sample_uuid, date, method)
        db.transaction(:rollback => :reraise) do
          case method
          when "create" then
            sample_id = create_sample_record(sample, date)
            create_uuid_record(sample_id, sample_uuid)
            study_name = study_name(sample.sanger_sample_id)
            study_sample_uuids = create_study_sample_records(sample_id, study_name)
            study_sample_uuids.each do |study_sample_uuid|
              bus.publish(study_sample_uuid)
            end
          when "update" then
            update_sample_record(sample, date, sample_uuid)
          when "delete" then
            delete_sample_record(sample_uuid)
          end
        end
      end

      # @param [Lims::ManagementApp::Sample] sample
      # @param [Time] date
      def create_sample_record(sample, date)
        sample_values = {
          :created_at => date,
          :updated_at => date
        }.merge(prepare_data(sample, :samples))
        sample_id = db[:samples].insert(sample_values)

        sample_metadata_values = prepare_data(sample, :sample_metadata)
        sample_metadata_values.merge!({
          :sample_id => sample_id,
          :created_at => date,
          :updated_at => date
        })
        db[:sample_metadata].insert(sample_metadata_values)
        sample_id
      end

      # @param [Fixnum] sample_id
      # @param [String] sample_uuid
      def create_uuid_record(sample_id, sample_uuid)
        db[:uuids].insert({
          :resource_type => settings["sample_type"],
          :resource_id => sample_id,
          :external_id => sample_uuid
        })
      end

      # @param [Fixnum] sample_id
      # @param [String] study_abbreviation
      # @return [Array<String>] study_sample uuids
      def create_study_sample_records(sample_id, study_abbreviation)
        studies = db[:study_metadata].where{ |s| {s.lower(:study_name_abbreviation) => s.lower(study_abbreviation)}}.all
        raise UnknownStudy, "The study #{study_abbreviation} cannot be found in Sequencescape" if studies.empty?

        [].tap do |uuids|
          studies.each do |study|
            study_id = study[:study_id]
            date = Time.now.utc
            study_sample_id = db[:study_samples].insert({
              :study_id => study_id, 
              :sample_id => sample_id,        
              :created_at => date,
              :updated_at => date
            })

            study_sample_uuid = SecureRandom.uuid
            uuids << study_sample_uuid
            db[:uuids].insert({
              :resource_type => settings["study_sample_type"],
              :resource_id => study_sample_id,
              :external_id => study_sample_uuid 
            })
          end
        end
      end

      # @param [String] sanger_sample_id
      # @return [String]
      def study_name(sanger_sample_id)
        sanger_sample_id.match(/^(.*)-[0-9]+$/)[1] 
      end

      # @param [Lims::ManagementApp::Sample] sample
      # @param [Time] date
      # @param [String] sample_uuid
      def update_sample_record(sample, date, sample_uuid)
        sample_uuid_record = db[:uuids].select(:resource_id).where(:external_id => sample_uuid).first
        raise UnknownSample, "The sample to update '#{sample_uuid}' cannot be found in Sequencescape" unless sample_uuid_record 
        sample_id = sample_uuid_record[:resource_id] 

        updated_attributes = prepare_data(sample, :samples) 
        updated_attributes.merge!({:updated_at => date})
        db[:samples].where(:id => sample_id).update(updated_attributes)

        updated_attributes = prepare_data(sample, :sample_metadata)
        updated_attributes.merge!(:updated_at => date)
        db[:sample_metadata].where(:sample_id => sample_id).update(updated_attributes)

        sample_id
      end

      # @param [String] sample_uuid
      def delete_sample_record(sample_uuid)
        sample_uuid_record = db[:uuids].select(:resource_id).where(:external_id => sample_uuid).first
        raise UnknownSample, "The sample to delete '#{sample_uuid}' cannot be found in Sequencescape" unless sample_uuid_record 
        sample_id = sample_uuid_record[:resource_id] 

        db[:uuids].where(:external_id => sample_uuid).delete
        db[:sample_metadata].where(:sample_id => sample_id).delete
        db[:samples].where(:id => sample_id).delete
        sample_id
      end

      # @param [Lims::ManagementApp::Sample] sample
      # @param [Symbol] table
      # @return [Hash]
      # Make the translation between sequencescape attribute names
      # and s2 attribute names.
      def prepare_data(sample, table)
        map = MAPPING[table]
        {}.tap do |h|
          map.each do |s_attribute, s2_attribute|
            if s2_attribute =~ /__(\w*)__(.*)/
              value = sample.send($1) if sample.respond_to?($1)
              h[s_attribute] = value.send($2) unless value.nil?
            else
              h[s_attribute] = sample.send(s2_attribute) if s2_attribute && sample.respond_to?(s2_attribute) 
            end
          end
        end
      end
    end
  end
end
