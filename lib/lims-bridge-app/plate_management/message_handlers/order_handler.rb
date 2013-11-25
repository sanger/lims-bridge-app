require 'lims-bridge-app/plate_management/base_handler'

module Lims::BridgeApp::PlateManagement
  module MessageHandler
    class OrderHandler < BaseHandler

      private

      # When an order message is received, we check if it contains
      # items whose role match an item_role_pattern with a done status.
      # For these items, we update the corresponding plate purpose id in
      # sequencescape.
      def _call_in_transaction
        order = s2_resource[:order]
        order_uuid = s2_resource[:uuid]
        date = s2_resource[:date]

        plate_items = plate_items(order)
        unless plate_items.empty?
          success = true
          plate_items.each do |items|
            items[:items].each do |item|
              if item.status == settings["item_done_status"]
                begin
                  plate_uuid = item.uuid
                  plate_purpose_id = plate_purpose_id(items[:role])
                  update_plate_purpose_in_sequencescape(plate_uuid, date, plate_purpose_id)
                  bus.publish(plate_uuid)
                rescue PlateNotFoundInSequencescape, Sequel::Rollback => e
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

      # Get all the plate items from an order which match a pattern
      # defined in item_role_patterns.
      # @param [Lims::Core::Organization::Order] order
      # @return [Array] plate items
      def plate_items(order)
        [].tap do |items|
          settings["item_role_patterns"].each do |pattern|
            order.each do |role, _|
              if role.match(pattern)
                items << {:role => role, :items => order[role]}
              end
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
