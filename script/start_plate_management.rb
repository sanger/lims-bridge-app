require 'yaml'
require 'lims-bridge-app'
require 'logging'

module Lims
  module BridgeApp
    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))["production"] 
    mysql_settings = YAML.load_file(File.join('config','database.yml'))["production"] 

    creator = PlateCreator::StockPlateConsumer.new(amqp_settings, mysql_settings)
    creator.set_logger(Logging::LOGGER)

    Logging::LOGGER.info("Plate Creator started")
    creator.start
    Logging::LOGGER.info("Plate Creator stopped")
  end
end
