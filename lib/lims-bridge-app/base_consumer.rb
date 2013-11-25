require 'lims-busclient'
require 'lims-bridge-app/s2_resource'

module Lims::BridgeApp
  class BaseConsumer
    include Lims::BusClient::Consumer
    include S2Resource

    InvalidParameters = Class.new(StandardError) 

    attribute :db, Sequel::Mysql2::Database, :required => true, :writer => :private, :reader => :private
    attribute :queue_name, String, :required => true, :writer => :private, :reader => :private
    attribute :log, Object, :required => false, :writer => :private
    attribute :bus, Lims::BridgeApp::MessageBus, :required => true, :writer => :private
    attribute :settings, Hash, :required => true, :writer => :private

    # @param [Class] subclass
    # Setup the validation of bridge settings
    def self.inherited(subclass)
      subclass.class_eval do
        include Virtus
        include Aequitas
        validates_with_method :settings_validation

        def settings_validation
          self.class::SETTINGS.each do |attribute, type|
            raise InvalidParameters, "The setting #{attribute} is required" unless settings[attribute.to_s]
            raise InvalidParameters, "The setting #{attribute} must be a #{type}" unless settings[attribute.to_s].is_a?(type)
          end
          true
        end
      end
    end

    # Initilize the SequencescapePlateCreator class
    # @param [String] queue name
    # @param [Hash] AMQP settings
    # @param [Hash] bridge settings
    def initialize(amqp_settings, mysql_settings, bridge_settings)
      sequencescape_bus_settings = amqp_settings.delete("sequencescape").first.tap do |settings|
        settings["backend_application_id"] = "lims-bridge-app"
      end
      @bus = MessageBus.new(sequencescape_bus_settings)
      @settings = bridge_settings
      consumer_setup(amqp_settings)
      sequencescape_db_setup(mysql_settings)
      set_queue
    end

    # @param [Logger] logger
    def set_logger(logger)
      @log = logger
    end

    private

    # Setup the Sequencescape database connection
    # @param [Hash] MySQL settings
    def sequencescape_db_setup(settings = {})
      @db = Sequel.connect(settings) unless settings.empty?
    end 

    def set_queue
      raise NotImplementedError
    end
  end
end
