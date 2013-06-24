require 'lims-core/persistence/message_bus'

module Lims::BridgeApp
  module MessageBus

    def bus_connection(settings)
      bus_settings = settings.mash do |k,v|
        case k
        when "sequencescape_exchange" then ["exchange_name", v]
        else [k,v]
        end
      end

      Lims::Core::Persistence::MessageBus.new(bus_settings).tap do |bus|
        bus.set_message_persistence(bus_settings["message_persistence"])
        bus.connect
      end
    end
  end
end
