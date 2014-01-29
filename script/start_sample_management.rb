require 'yaml'
require 'lims-bridge-app'
require 'logging'

module Lims
  module BridgeApp
    env = ENV["LIMS_BRIDGE_APP_ENV"] or raise "LIMS_BRIDGE_APP_ENV is not set in the environment"

    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]
    bridge_data = YAML.load_file(File.join('config', 'bridge.yml'))
    bridge_settings = bridge_data[env] || bridge_data['default']

    consumer = SampleManagementConsumer.new(amqp_settings, bridge_settings)
    consumer.set_logger(Logging::LOGGER)

    Logging::LOGGER.info("Sample management started")
    consumer.start
    Logging::LOGGER.info("Sample management stopped")
  end
end
