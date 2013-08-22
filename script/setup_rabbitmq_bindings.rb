require 'optparse'
require 'yaml'
require 'json'

# This script setups the bindings between a queue and an exchange.
# For each routing key found in config/routing_keys.yml, it binds
# the queue to the exchange with the routing key. 
# The url passed in the parameters must be like /api/bindings/vhost/e/exchange/q/queue
# Example:
# bundle exec ruby script/setup_rabbitmq_bindings.rb 
# -u guest
# -p guest
# -q plate 
# -a http://localhost:15672/api/bindings/%2f/e/psd.s2/q/psd.s2.plates

options = {}
OptionParser.new do |opts|
  opts.on("-u", "--user [USER]") { |v| options[:user] = v }
  opts.on("-p", "--password [PASSWORD]") { |v| options[:password] = v }
  opts.on("-q", "--queue [QUEUE]") { |v| options[:queue] = v }
  opts.on("-a", "--api [API]") { |v| options[:api] = v }
end.parse!

options[:queue] = case options[:queue]
                  when /plate/ then "plate_management"
                  when /sample/ then "sample_management"
                  end

unless options[:user] && options[:password] && options[:api] && options[:queue]
  abort "User, password, url and queue name need to be set." 
end

routing_keys = YAML.load_file(File.join('config', 'routing_keys.yml'))[options[:queue]]
routing_keys.each do |routing_key|
  parameters = {:routing_key => routing_key}.to_json
  curl = "curl -u #{options[:user]}:#{options[:password]} -H 'Content-Type: application/json' -X POST -d '#{parameters}' #{options[:api]}"
  system(curl)
end

puts
puts "Setup done!"
