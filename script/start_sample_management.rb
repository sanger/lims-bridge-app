env = ENV["LIMS_BRIDGE_APP_ENV"] or raise "LIMS_BRIDGE_APP_ENV is not set in the environment"

require 'yaml'
require 'lims-bridge-app'
require 'logging'

module Lims
  module BridgeApp
    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]
    mysql_settings = YAML.load_file(File.join('config','database.yml'))[env]

    management = SampleManagement::SampleConsumer.new(amqp_settings, mysql_settings)
    management.set_logger(Logging::LOGGER)

    Logging::LOGGER.info("Sample consumer started")
    management.start
    Logging::LOGGER.info("Sample consumer stopped")
  end
end
