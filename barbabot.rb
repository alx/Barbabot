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
  property :im_account, String
end

class Channel
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
end