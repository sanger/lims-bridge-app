require 'yaml'
require 'lims-bridge-app'
require 'logging'
require 'lims-exception-notifier-app/exception_notifier'

module Lims
  module BridgeApp
    env = ENV["LIMS_BRIDGE_APP_ENV"] or raise "LIMS_BRIDGE_APP_ENV is not set in the environment"

    amqp_settings = YAML.load_file(File.join('config','amqp.yml'))[env]
    mysql_settings = YAML.load_file(File.join('config','database.yml'))[env]

    bridge_data = YAML.load_file(File.join('config', 'bridge.yml'))
    bridge_settings = (bridge_data[env] || bridge_data['default'])['sample_management']

    notifier = Lims::ExceptionNotifierApp::ExceptionNotifier.new

    begin
      management = SampleManagement::SampleConsumer.new(amqp_settings, mysql_settings, bridge_settings)
      management.set_logger(Logging::LOGGER)

      Logging::LOGGER.info("Sample consumer started")
      notifier.notify do
        management.start
      end
    rescue StandardError, LoadError, SyntaxError => e
      # log the caught exception
      notifier.send_notification_email(e)
    end
    Logging::LOGGER.info("Sample consumer stopped")
  end
end
