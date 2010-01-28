require 'rubygems'
require 'xmpp4r-simple'
require 'daemons'

gem 'dm-core'
gem 'dm-timestamps'

require 'dm-core'
require 'dm-timestamps'

# Initialize the app while we're not a daemon
DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/barbabot.db")

config = YAML.load_file('barbabot.yaml')
messenger = Jabber::Simple.new(config['account']['email'], config['account']['password'])

class User
  include DataMapper::Resource
  property :id, Serial
  property :im_name, String
end

# Become a daemon
Daemons.daemonize

while true
  messenger.received_messages do |msg|
    unless user = User.first(:im_name => msg.from.to_s)
      User.create(:im_name => msg.from.to_s)
      messenger.add(msg.from)
      messenger.deliver(msg.from, "Bienvenue sur barbabot")
    end
    User.all.each do |user|
      messenger.deliver(user.im_name, "#{msg.from.to_s.split("@").first}: #{msg.body}") if user.im_name != msg.from.to_s
    end
  end  
  sleep 1
end