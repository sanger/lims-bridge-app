require 'lims-bridge-app/base_decoder'
require 'lims-laboratory-app/organization/order'

module Lims::BridgeApp
  module Decoders
    class OrderDecoder < BaseDecoder

      private

      # @return [Lims::LaboratoryApp::Organization::Order]
      def decode_order
        Lims::LaboratoryApp::Organization::Order.new.tap do |order|
          resource_hash["items"].each do |role, settings|
            settings.each do |s|
              items = order.fetch(role) { |_| order[role] = [] }
              items << Lims::LaboratoryApp::Organization::Order::Item.new({
                :uuid => s["uuid"],
                :status => s["status"]
              })
            end
          end
        end
      end
    end
  end
end
