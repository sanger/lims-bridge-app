module Lims::BridgeApp
  class SequencescapeWrapper
    InvalidBarcode = Class.new(StandardError)

    module Barcode
      Pattern = [8, 4, 4, 4, 12]
      UuidWithoutDashes = /#{Pattern.map { |n| "(\\w{#{n}})"}.join}/i

      # @param [Lims::LaboratoryApp::Labels::Labellable] labellable
      # @raise [InvalidBarcode, AssetNotFound]
      def barcode_an_asset(labellable)
        asset_uuid = labellable.name
        asset_uuid = Regexp.last_match[1..5].join("-") if plate_uuid =~ UuidWithoutDashes
        asset_id = asset_id_by_uuid(asset_uuid)
        barcode = sanger_barcode(labellable)
        prefix = barcode[:prefix]

        unless settings["barcode_prefixes"].keys.map { |p| p.downcase }.include?(prefix.downcase)
          raise InvalidBarcode, "#{prefix} is not a supported barcode prefix"
        end

        barcode_prefix_id = barcode_prefix_id(prefix)
        asset_name = "#{settings["barcode_prefixes"][prefix]} #{barcode[:number]}"

        SequencescapeModel::Asset[:id => asset_id].tap do |asset|
          asset.name = asset_name
          asset.barcode = barcode[:number]
          asset.barcode_prefix_id = barcode_prefix_id
          asset.updated_at = date
        end.save
      end

      private

      # @param [Lims::LaboratoryApp::Labels::Labellable] labellable
      # @return [Hash]
      # Return the first sanger barcode found in the labellable
      # The preceeding zeroes from the barcode are stripped for sequencescape.
      def sanger_barcode(labellable)
        labellable.each do |position, label|
          if label.type == settings["sanger_barcode_type"]
            label.value.match(/^(\w{2})([0-9]*)\w$/)
            prefix = $1
            number = $2.to_i.to_s
            return {:prefix => prefix, :number => number} 
          end
        end
      end

      # @param [String] prefix
      # @return [Integer]
      # Return the prefix id. Create the prefix if it does not exist yet.
      def barcode_prefix_id(prefix)
        prefix_model = SequencescapeModel::BarcodePrefixe.get_or_create(:prefix => prefix)
        prefix_model.save.tap do |saved_prefix|
          return saved_prefix.id
        end
      end
    end
  end
end
