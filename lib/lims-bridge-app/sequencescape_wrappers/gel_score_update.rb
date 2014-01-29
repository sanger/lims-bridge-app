module Lims::BridgeApp
  class SequencescapeWrapper

    module GelScoreUpdate
      # @param [Lims::QualityApp::GelImage] gel_image
      def update_gel_scores(gel_image)
        unless gel_image.scores.empty?
          gel_id = asset_id_by_uuid(gel_image.gel_uuid)
          gel_image.scores.each do |location, score|
            well_id = well_id_by_location(gel_id, location)

            # TODO : exclude is used to exclude the identity transfer 
            # which could be found sometimes. To be fixed.
            stock_well = SequencescapeModel::Request.from_self(:alias => :requests_stock_wd).join(
              :requests, :asset_id => :requests_stock_wd__target_asset_id
            ).select(:requests_stock_wd__asset_id).where(
              :requests__target_asset_id => well_id
            ).exclude(:requests__asset_id => well_id).first

            next unless stock_well
            stock_well_id = stock_well.asset_id

            SequencescapeModel::WellAttribute.get_or_create(:well_id => stock_well_id).tap do |well_attribute|
              well_attribute.gel_pass = settings["gel_image_s2_scores_to_sequencescape_scores"][score]
              well_attribute.updated_at = date
              well_attribute.created_at = date unless well_attribute.created_at
            end.save
          end
        end
      end
    end
  end
end
