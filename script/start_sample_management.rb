ENV["LIMS_BRIDGE_ENV"] = "development" unless ENV["LIMS_BRIDGE_ENV"]

require 'yaml'
require 'lims-bridge-app'
require 'logging'

module Lims
  module BridgeApp
    env = ENV["LIMS_BRIDGE_ENV"]
    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]
    mysql_settings = YAML.load_file(File.join('config','database.yml'))[env]

    management = SampleManagement::SampleConsumer.new(amqp_settings, mysql_settings)
    management.set_logger(Logging::LOGGER)

    Logging::LOGGER.info("Sample consumer started")
    management.start
    Logging::LOGGER.info("Sample consumer stopped")
  end
end
