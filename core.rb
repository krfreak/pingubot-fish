require 'bundler/setup'
require 'discordrb'
require 'json'

module Bot
  cfg_file = File.read('config/config.json')
  CFG = JSON.parse(cfg_file)

  BOT = Discordrb::Commands::CommandBot.new token: CFG['token'], client_id: CFG['app_id'], prefix: CFG['prefix']

  module Fish; end
  Dir['fish/*.rb'].each { |fish| load fish }
  Fish.constants.each do |fish|
    BOT.include! Fish.const_get fish
  end

  BOT.command(:ping, description: "measure this bot's response time") do |event|
    m = event.respond('Pong!')
    m.edit "Pong! Time taken: #{Time.now - event.timestamp} seconds."
    nil
  end

  BOT.command(:exit, help_available: false) do |event|
    break unless event.user.id == CFG['owner_id'] # Replace number with your ID

    BOT.send_message(event.channel.id, 'Nooting down.')
    exit
  end

  BOT.run
end
