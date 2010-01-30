require 'rubygems'
require 'xmpp4r-simple'

require 'net/http'

require 'atom/entry' # sudo gem install atom-tools
require 'atom/collection'

require 'dm-core'
require 'dm-timestamps'

gem 'rif'
require 'rif/bot'

DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/barbabot.db")

config = YAML.load_file('barbabot.yaml')

class User
  include DataMapper::Resource
  property :id, Serial
  property :im_name, String
  property :is_active, Boolean, :default => true
end

class Pressmark
  
  def initialize(config = {})
    @blog_uri = config["uri"]
    @username = config["username"]
    @password = config["password"]
  end
  
  def post(url, author, description = nil)
    entry = Atom::Entry.new
    entry.title = url
    entry.updated!

    author = Atom::Author.new
    author.name = author.split("@").first
    author.email = author.split("/").first
    author.uri = @bloguri
    entry.authors << author
    
    entry.content = description
    entry.content["type"] = 'html'

    h = Atom::HTTP.new
    h.user = @username
    h.pass = @password
    h.always_auth = :basic

    c = Atom::Collection.new(@bloguri + "/wp-app.php/posts", h)
    c.post! entry
  end
  
end

class BarbabotIrc < RIF::Bot
  
  def initialize(nick, server, port, name)
    super
    @messages = ""
  end
  
  def on_endofmotd(event)
    join("#tetalab")
  end
  
  def on_message(event)
    @messages += "<#{event.nick}>: #{event.message}\n"
  end
  
  def deliver(msg)
    send_message("#tetalab", msg)
  end
end

@messenger = Jabber::Simple.new(config['account']['email'], config['account']['password'])

if config['pressmark']
  @pressmark = Pressmark.new(config['pressmark'])
end

# @irc = BarbabotIrc.new("barbabot", "irc.freenode.net", 6667, "Barbabot")
# @irc.connect

while true
  
  # unless @irc.messages.empty?
  #   User.all(:im_name.not => msg.from.to_s, :is_active => true).each do |user|
  #     @messenger.deliver(user.im_name, @irc.messages)
  #   end
  #   @irc.messages = ""
  # end
  
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
    when /^\/url\s(.*)\s(.*)$/i
      @pressmark.post($1, msg_from, $2)
      @messenger.deliver(msg.from, "Url envoyée sur http://bookmark.tetalab.org")
    else
      User.all(:im_name.not => msg_from, :is_active => true).each do |user|
        @messenger.deliver(user.im_name, "#{msg.from.to_s.split("@").first}: #{msg.body}")
      end
      # @irc.deliver("#{msg.from.to_s.split("/").first}: #{msg.body}")
    end
  end
  sleep 1
end