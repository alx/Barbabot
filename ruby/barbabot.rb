require 'rubygems'
require 'xmpp4r-simple'
require 'dm-core'
require 'dm-timestamps'

DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/barbabot.db")

config = YAML.load_file('barbabot.yaml')
@messenger = Jabber::Simple.new(config['account']['email'], config['account']['password'])

class User
  include DataMapper::Resource
  property :id, Serial
  property :im_name, String
  property :activated, Boolean, :default => true
end

while true
  @messenger.received_messages do |msg|
    unless user = User.first(:im_name => msg.from.to_s)
      User.create(:im_name => msg.from.to_s)
      @messenger.add(msg.from)
      @messenger.deliver(msg.from, "Bienvenue sur barbabot - /help pour la liste des commandes")
    end
    
    case msg.body
    when /^\/help$/i
      @messenger.deliver(msg.from, "/help Cette aide\n/names Liste des membres actifs\n/up Activer le chat (par defaut)\n/down Désactiver le chat")
    when /^\/names$/i
      user.update :activated => true
      names = "Utilisateurs actifs:\n"
      User.all(:im_name.not => msg.from.to_s, :activated => true).each{|u| names << "#{user.im_name}\n"}
      @messenger.deliver(msg.from, names)
    when /^\/up$/i
      user.update :activated => true
      @messenger.deliver(msg.from, "Chat activé")
    when /^\/down$/i
      user.update :activated => false
      @messenger.deliver(msg.from, "Chat désactivé")
    else
      User.all(:im_name.not => msg.from.to_s, :activated => true).each do |user|
        @messenger.deliver(user.im_name, "#{msg.from.to_s.split("@").first}: #{msg.body}")
      end
    end
  end
  sleep 1
end