# Usage: $ PUSHER_KEY=YOURKEY ruby examples/hello_pusher.rb

$:.unshift(File.expand_path("../../lib", __FILE__))
require 'pusher-client'
require 'pp'

APP_KEY = ENV['PUSHER_KEY'] # || "YOUR_APPLICATION_KEY"

socket = PusherClient::Socket.new(APP_KEY)

# Subscribe to a channel
socket.subscribe('hellopusher')

# Bind to a channel event
socket['hellopusher'].bind('hello') do |data|
  pp data
end

socket.connect
