require 'lims-bridge-app/plate_creator/sequencescape_updater'
require 'common'

module Lims::BridgeApp::PlateCreator
  module MessageHandler
    class BaseHandler
      include SequencescapeUpdater

      # Fix for a bug in Aequitas which doesn't support
      # correctly class inheritance.
      def self.inherited(klass)
        klass.class_eval do
          include Virtus
          include Aequitas
          attribute :db, Sequel::MySQL::Database, :required => true, :writer => :private, :reader => :private
          attribute :metadata, AMQP::Header, :required => true, :writer => :private, :reader => :private
          attribute :s2_resource, Hash, :required => true, :writer => :private, :reader => :private
          attribute :log, Object, :required => true, :writer => :private, :reader => :private 

          # @param [Sequel::MySQL::Database] db
          # @param [Object] log
          # @param [AMQP::Header] metadata
          # @param [Hash] s2_resource
          def initialize(db, log, metadata, s2_resource)
            @db = db
            @log = log
            @metadata = metadata
            @s2_resource = s2_resource
          end
        end
      end

      def _call_in_transaction
        raise NoMethodError
      end
    end
  end
end
