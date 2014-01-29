# Lims-bridge-app

[![Build Status](https://travis-ci.org/llh1/lims-bridge-app.png?branch=52629993_refactoring)](https://travis-ci.org/llh1/lims-bridge-app)

Lims-bridge-app creates a bridge from S2 to Sequencescape. It is used for different S2 actions in order to replicate them into Sequencescape.
In particular, lims-bridge-app is responsible to create and update S2 plates/tube racks/samples in Sequencescape.
Everytime an action is performed using S2, a message is sent on the bus and some of them are used by the bridge to update accordingly Sequencescape.

## Usage 

Currently, the bridge has 2 entry points: one consumer which deal with plate/racks related messages, and an other consumer dealing with sample related messages. 
To start them:

- bundle exec ruby script/start\_plate\_management.rb
- bundle exec ruby script/start\_sample\_management.rb

or to start the consumer as daemons (replace <identity> with the worker name):

- sh script/worker plate <identity> start 
- sh script/worker sample <identity> start 

## Development

To add support for another kind of S2 messages, you need:

- add the new the corresponding routing key in config/routing\_keys.yml
- use the script script/setup\_rabbitmq\_bindings.rb to setup the corresponding queue with the new routing key 
- OR manually add the new routing key in the rabbitmq queue configuration

- edit the consumer class to declare a route for the new routing key
- add a decoder for the resource embedded in the message
- add a message handler class which is responsible of the high level behaviour of the bridge to that message (call the sequencescape methods, handle errors, acknowledge or reject messages, etc...)
- add the needed method to update sequencescape under sequencescape\_wrappers/

Below are some notes about some assumptions you'll need to know when developing new things:

### Consumers

In the route\_for method, we associate a matching pattern of the routing key, to a symbol. The symbol is the name of the message handler class.
Example: :asset\_creation assumes an AssetCreationHandler class exists under message\_handlers/

### Decoders

Decoders decode message payload and map it to a S2 core resource.
BaseDecoder adds some default behaviour to all the child decoders. Any decoders return a hash, containing the decoded resource (each decoder is responsible for that bit) and the base decoder adds the following information in the returned hash: uuid and date. 
The decoder class are named after the first key appearing in the message payload (usually the resource model or the s2 action name). For example, if a message with the payload like {"plate":{...},"date":"...","action":"...","user":"..."} is received, the decoder PlateDecoder will be called.

### Message Handlers 

As said above in the Consumers section, the route defined in the consumer in the route\_for method should match the handler class name.
A new message handler class must define the "\_call\_in\_transaction" method. Everything which is done in this method is embedded in a Sequel transaction.
Each message handler class can access to the following attributes defined in the base\_handler class:

- sequencescape: an instance of SequencescapeWrapper and contains all the actions the bridge can do in Sequencescape database
- bus: an instance of the MessageBus class to publish newly created resource uuid on the bus, so the Sequencescape Warehouse can be updated.
- log: instance of the logger
- settings: all the settings defined under config/bridge.yml
- metadata: message metadata

Attention: when catching an error in a handler class, a Sequel::Rollback exception MUST be raised, so the transaction is rollbacked at a higher level.

### Sequencescape Wrappers

High level methods to update Sequencescape database. Sequel models are automatically created for each table of Sequencescape in the module SequencescapeModel. 
Each of these models have the method "get\_or\_create" taking a hash, and returning a model instance associated to a record in the table if found any, or a new model
instance setting the criteria in the hash.

By default, Sequel assumes that the name of the table in Sequencescape database corresponds to the plural of the model class name. 
Example: Asset model class corresponds to the table assets in the database.
To change this behaviour, one can use the class method "set\_dataset" to set the name of the table.

