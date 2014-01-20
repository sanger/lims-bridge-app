require 'lims-bridge-app/base_handler'

module Lims::BridgeApp
  module MessageHandlers
    class OrderHandler < BaseHandler

      private

      # When an order message is received, we check if it contains
      # items whose role match an item_role_pattern with a done status.
      # For these items, we update the corresponding plate purpose id in
      # sequencescape.
      def _call_in_transaction
        order = resource[:order]
        order_uuid = resource[:uuid]
        order_items = order_items(order)

        unless order_items.empty?
          success = true
          order_items.each do |items|
            items[:items].each do |item|
              if item.status == settings["item_done_status"]
                begin
                  asset_uuid = item.uuid
                  plate_purpose_id = plate_purpose_id(items[:role])
                  sequencescape.update_plate_purpose(asset_uuid, plate_purpose_id)
                  bus.publish(asset_uuid)
                rescue SequencescapeWrapper::AssetNotFound, Sequel::Rollback => e
                  success = false
                  log.info("Error updating plate in Sequencescape: #{e}")
                else
                  success = success && true
                end
              end
            end
          end

          if success
            metadata.ack
            log.info("Order message processed and acknowledged")
          else
            metadata.reject(:requeue => true)
            raise Sequel::Rollback # Rollback the transaction
          end
        else
          metadata.ack
          log.info("Order message processed and acknowledged")
        end
      end

      # Get all the items from an order which match a pattern
      # defined in item_role_patterns.
      # @param [Lims::Core::Organization::Order] order
      # @return [Array] order items
      def order_items(order)
        [].tap do |items|
          settings["item_role_patterns"].each do |pattern|
            order.each do |role, _|
              items << {:role => role, :items => order[role]} if role.match(pattern)
            end
          end
        end
      end

      # @param [String] role
      # @return [Integer]
      def plate_purpose_id(role)
        purpose_id = settings["roles_purpose_ids"][role]
        purpose_id = settings["unassigned_plate_purpose_id"] unless purpose_id
        purpose_id
      end
    end
  end
end
