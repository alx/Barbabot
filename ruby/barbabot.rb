require 'rubygems'
require 'xmpp4r-simple'

require 'net/http'

require 'dm-core'
require 'dm-timestamps'

DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/barbabot.db")

config = YAML.load_file('barbabot.yaml')

class User
  include DataMapper::Resource
  property :id, Serial
  property :im_name, String
  property :is_active, Boolean, :default => true
end

@messenger = Jabber::Simple.new(config['account']['email'], config['account']['password'])

while true
  
  @messenger.received_messages do |msg|
    
    msg_from = msg.from.to_s.split("/").first
    
    # New user has come to say something, register him
    unless user = User.first(:im_name => msg_from)
      User.create(:im_name => msg_from)
      @messenger.add(msg.from)
      @messenger.deliver(msg.from, "Bienvenue sur barbabot - /help pour la liste des commandes")
    end
    
    
    case msg.body
    when /^\/help$/i
      @messenger.deliver(msg.from, "/help\t\tCette aide\n/names\t\tListe des membres actifs\n/up\t\tActiver le chat (par defaut)\n/down\t\tDésactiver le chat")
    when /^\/names$/i
      names = "Utilisateurs actifs:\n"
      User.all(:im_name.not => msg_from, :is_active => true).each{|u| names += "\t- #{u.im_name}\n"}
      @messenger.deliver(msg.from, names)
    when /^\/up$/i
      user.is_active = true
      user.save
      @messenger.deliver(msg.from, "Chat activé")
    when /^\/down$/i
      user.is_active = false
      user.save
      @messenger.deliver(msg.from, "Chat désactivé")
    else
      User.all(:im_name.not => msg_from, :is_active => true).each do |user|
        @messenger.deliver(user.im_name, "#{msg_from.split("@").first}: #{msg.body}")
      end
      # @irc.deliver("#{msg.from.to_s.split("/").first}: #{msg.body}")
    end
  end
  sleep 1
end