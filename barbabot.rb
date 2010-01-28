require 'rubygems'
require 'xmpp4r-simple'

gem 'dm-core'
gem 'dm-timestamps'

require 'dm-core'
require 'dm-timestamps'

DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/barbabot.db")

config = YAML.load_file('barbabot.yaml')
messenger = Jabber::Simple.new(config['account']['email'], config['account']['password'])

class User
  include DataMapper::Resource
  property :id, Serial
  property :im_name, String
end

while true
  messenger.received_messages do |msg|
    unless user = User.first(:im_name => msg.from.to_s)
      User.create(:im_name => msg.from.to_s)
      messenger.add(msg.from)
      messenger.deliver(msg.from, "Bienvenue sur barbabot")
    end
    User.all do |user|
      p "deliver: #{user.im_name} - #{msg.from.to_s.split("@").first}: #{msg.body}"
      messenger.deliver(user.im_name, "#{msg.from.to_s.split("@").first}: #{msg.body}") if user.im_name != msg.from.to_s
    end
  end  
  sleep 1
end