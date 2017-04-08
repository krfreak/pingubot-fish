require 'concurrent'
require 'mtg_sdk'

module Bot
  module Fish
    module MTGCardFetcher
      extend Discordrb::Commands::CommandContainer
      puts "MTG Card Fetcher loaded"
      command :card do |event, *args|
        a = Concurrent::Promise.fulfill(MTG::Card.where(name: "#{args.join(' ')}").all.first).then{|result|
          if result.image_url.nil?
            begin
              event.channel.send_embed do |embed|
                embed.title = "#{result.name}"
                embed.colour = 0x14506f
                embed.image = Discordrb::Webhooks::EmbedImage.new(url: "#{result.image_url}")
                embed.add_field(name: "Colour:", value: result.colors.reject(&:empty?).join(', '))
                embed.add_field(name: "Mana cost:", value: result.mana_cost)
                embed.add_field(name: "Type line:", value: result.type)
                embed.add_field(name: "Types:", value: result.types.reject(&:empty?).join(', '))
                embed.add_field(name: "Rulings:", value: result.text)
                embed.add_field(name: "Power/Toughness:", value: "#{result.power}/#{result.toughness}") if result.types.include?("Creature")
              end
            rescue Discordrb::Errors::NoPermission
              text = ""
              text << "**Colour:** " << result.colors.reject(&:empty?).join(', ')
              text << "**Mana cost:** " << result.mana_cost
              text << "**Type line:**" <<  result.type
              text << "**Types:**" <<  result.types.reject(&:empty?).join(', ')
              text << "**Rulings:**" <<  result.text
              if result.types.include?("Creature")
                text << "**Power/Toughness:**" << "#{result.power}/#{result.toughness}"
              end
              event.channel.send_message "#{text}"
            end
          else
            begin
              event.channel.send_embed do |embed|
                embed.colour = 0x14506f
                embed.image = Discordrb::Webhooks::EmbedImage.new(url: "#{result.image_url}")
              end
            rescue Discordrb::Errors::NoPermission
              event.channel.send_message "#{result.image_url}"
            end
          end
        }
        a.execute.rescue{|reason|
          event.channel.send_message "No results."
        }
        nil
      end
    end
  end
end
