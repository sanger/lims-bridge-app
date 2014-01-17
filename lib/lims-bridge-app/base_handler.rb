require 'amqp'
require 'sequel/adapters/mysql2'
require 'lims-bridge-app/message_bus'
require 'virtus'
require 'aequitas/virtus_integration'
require 'lims-bridge-app/sequencescape_wrapper'

module Lims::BridgeApp
  module MessageHandlers
    UndefinedHandler = Class.new(StandardError)

    # @param [String] name
    # @return [Class]
    def self.handler_for(name)
      begin
        handler_class_name = "#{name.to_s.capitalize.gsub(/_./) {|p| p[1].upcase}}Handler"
        MessageHandlers::const_get(handler_class_name)
      rescue NameError => e
        raise UndefinedHandler, "#{handler_class_name} is undefined"
      end
    end

    class BaseHandler
      # Fix for a bug in Aequitas which doesn't support
      # correctly class inheritance.
      def self.inherited(klass)
        klass.class_eval do
          include Virtus
          include Aequitas
          attribute :sequencescape, Lims::BridgeApp::SequencescapeWrapper, :required => true, :writer => :private, :reader => :private
          attribute :metadata, ::AMQP::Header, :required => true, :writer => :private, :reader => :private
          attribute :resource, Hash, :required => true, :writer => :private, :reader => :private
          attribute :log, Object, :required => true, :writer => :private, :reader => :private 
          attribute :bus, Lims::BridgeApp::MessageBus, :required => true, :writer => :private
          attribute :settings, Hash, :required => true, :writer => :private

          # @param [Lims::Core::Persistence::MessageBus] bus
          # @param [Object] log
          # @param [AMQP::Header] metadata
          # @param [Hash] resource
          # @param [Hash] settings
          def initialize(bus, log, metadata, resource, settings)
            @sequencescape = Lims::BridgeApp::SequencescapeWrapper.new(settings)
            @sequencescape.date = resource[:date]
            @bus = bus
            @log = log
            @metadata = metadata
            @resource = resource
            @settings = settings
          end
        end
      end

      def call
        sequencescape.call do 
          _call_in_transaction
        end
      end

      def _call_in_transaction
        raise NotImplementedError
      end
      private :_call_in_transaction
    end
  end
end
