ENV["LIMS_BRIDGE_ENV"] = "development" unless ENV["LIMS_BRIDGE_ENV"]

require 'yaml'
require 'lims-bridge-app'
require 'logging'

module Lims
  module BridgeApp
    env = ENV["LIMS_BRIDGE_ENV"]
    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]
    mysql_settings = YAML.load_file(File.join('config','database.yml'))[env]

    creator = PlateCreator::StockPlateConsumer.new(amqp_settings, mysql_settings)
    creator.set_logger(Logging::LOGGER)

    Logging::LOGGER.info("Plate Creator started")
    creator.start
    Logging::LOGGER.info("Plate Creator stopped")
  end
end
