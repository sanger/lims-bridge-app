require 'lims-bridge-app/sequencescape_wrappers/sequencescape_mapper'

module Lims::BridgeApp
  class SequencescapeWrapper
    UnknownStudy = Class.new(StandardError)

    module Sample
      include SequencescapeMapper

      # @param [Lims::ManagementApp::Sample] sample
      # @return [Integer] sample id
      def create_sample(sample)
        sample_values = prepare_sample_data(sample, :samples).merge({:created_at => date, :updated_at => date})         
        saved_sample = SequencescapeModel::Sample.new(sample_values).save
        sample_id = saved_sample.id

        sample_metadata_values = prepare_sample_data(sample, :sample_metadata).merge!({
          :sample_id => sample_id, :created_at => date, :updated_at => date
        })
        SequencescapeModel::SampleMetadata.new(sample_metadata_values).save

        sample_id
      end

      # @param [Lims::ManagementApp::Sample] sample
      # @param [String] sample_uuid
      def update_sample(sample, sample_uuid)
        asset_id_by_uuid(sample_uuid).tap do |sample_id|
          attributes_to_update = prepare_sample_data(sample, :samples).merge!(:updated_at => date)
          SequencescapeModel::Sample.where(:id => sample_id).update(attributes_to_update)

          attributes_to_update = prepare_sample_data(sample, :sample_metadata).merge!(:updated_at => date)
          SequencescapeModel::SampleMetadata.where(:sample_id => sample_id).update(attributes_to_update)
        end
      end

      # @param [String] sample_uuid
      def delete_sample(sample_uuid)
        asset_id_by_uuid(sample_uuid).tap do |sample_id|
          SequencescapeModel::Uuid[:external_id => sample_uuid].delete
          SequencescapeModel::SampleMetadata[:sample_id => sample_id].delete
          SequencescapeModel::Sample[:id => sample_id].delete
        end
      end
      
      # @param [Integer] sample_id
      # @param [String] study_abbreviation
      # @return [Array<String>] study sample uuids
      def create_study_sample(sample_id, study_abbreviation)
        studies = SequencescapeModel::StudyMetadata.where{ |s| {s.lower(:study_name_abbreviation) => s.lower(study_abbreviation)}}.all
        raise UnknownStudy, "The study #{study_abbreviation} cannot be found in Sequencescape" if studies.empty?

        [].tap do |uuids|
          studies.each do |study_metadata|
            now = Time.now.utc
            saved_study_sample = SequencescapeModel::StudySample.new.tap do |ss|
              ss.study_id = study_metadata.study_id
              ss.sample_id = sample_id
              ss.created_at = now
              ss.updated_at = now
            end.save

            study_sample_id = saved_study_sample.id
            study_sample_uuid = SecureRandom.uuid
            create_uuid(settings["study_sample_type"], study_sample_id, study_sample_uuid) 
            uuids << study_sample_uuid
          end
        end
      end

      # @param [Lims::ManagementApp::Sample] sample
      # @param [Symbol] table
      # @return [Hash]
      # Make the translation between sequencescape attribute names
      # and s2 attribute names.
      def prepare_sample_data(sample, table)
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
