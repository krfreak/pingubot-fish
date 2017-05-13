module Bot
  module Fish
    module Vampirism
      extend Discordrb::Commands::CommandContainer
      puts 'Vampirism loaded'

      command :bite, description: "Let's Pingu bite you or another user" do |event|
        next if event.channel.id == 83917313761378304
        user_id = get_user_id event
        return nil if user_id == 150647025493475328
        user = get_user user_id
        rnd = rand()
        turns_into_vampire = rnd > 0.95 && !user.is_vampire?
        user.update(is_vampire: true) if turns_into_vampire
        "**bites <@#{user_id}> and drinks #{rnd} litres of blood.**  Delicious! #{turns_into_vampire == true ? "<@#{user_id}> turns into a vampire. <@#{user_id}> walks now among the undead." : ""}"
      end

      command :stake, description: "Stakes a user. If the user is a vampire he will be no longer one." do |event|
        next if event.channel.id == 83917313761378304
        user_id = get_user_id event
        user = get_user user_id
        author = get_user event.message.author.id
        if event.message.mentions.blank?
          "**Hands <@#{user_id}> a wooden stake and a hammer**"
        else
          if user.is_vampire?
            if user.creator_id == author.user_id
              return "**You are unable to raise your hand against your creator.**"
            end
            rnd = rand()
            if rnd > 0.95
              "**As <@#{user_id}> drives a wooden stake through <@#{event.message.mentions.first.id}>'s heart, <@#{event.message.mentions.first.id}> crumbles to dust. <@#{event.message.mentions.first.id}> no longer walks among the undead.**"
              user.update(is_vampire: false)
            else
              "**As <@#{event.message.author.id}> tries to drive a stake through <@#{user_id}>'s heart, <@#{user_id}> laughs maddeningly and bites <@#{event.message.author.id}>, drinking #{rand()*2} litres of blood.**"
            end
          else
            "That would kill <@#{event.message.mentions.first.id}>. Call the police!"
          end
        end
      end

      command :donate, description: "Donate some of your precious blood to the blood bank" do |event|
        next if event.channel.id == 83917313761378304
        bank = get_bank
        user_id = event.message.author.id
        user = get_user user_id
        rnd = rand()
        bank.update(blood_amount: bank.blood_amount + rnd, donors: bank.donors << user_id)
        if !user.is_vampire?
          "Thank you for donating #{rnd} litres of blood to our great cause!"
        else
          "You are a vampire, we don't take blood from you."
        end
      end

      command :blood, description: "Takes some blood out of the blood bank" do |event|
        next if event.channel.id == 83917313761378304
        user_id = event.message.author.id
        user = get_user user_id
        bank = get_bank
        if user.is_vampire?
          rnd = rand()
          if rnd < bank.blood_amount
            bank.update(blood_amount: bank.blood_amount - rnd)
            "**Takes a #{["A", "B", "AB", "O"].sample}#{["+","-"].sample} blood infusion containing #{rnd} litres of blood and hands it to <@#{user_id}>.**   Enjoy!"
          elsif bank.blood_amount <= 0
            bank.update(blood_amount = 0)
            "We're sorry but we ran out of blood. Consider donating some blood to our great cause!"
          else
            rnd = bank.blood_amount
            "**Takes a #{["A", "B", "AB", "O"].sample}#{["+","-"].sample} blood infusion containing #{rnd} litres of blood and hands it to <@#{user_id}>.**  This was our last reserve! Enjoy!"
          end
        else
          "We don't serve blood to the likes of you. Consider donating to our great cause. !!donate"
        end
      end

      command :creator, description: "Tells you who created you." do |event|
        next if event.channel.id == 83917313761378304
        user_id = get_user_id event
        user = get_user user_id
        user.is_vampire? ? "Your recieved the gift of darkness from <@#{user.creator_id}>." : "Your parents."
      end

      command :vamp, description: "Tells if you are a vampire or not." do |event|
        next if event.channel.id == 83917313761378304
        user_id = get_user_id event
        user = get_user user_id
        user.is_vampire? ? "You walk among the undead." : "You are not walking among the undead."
      end

      command :turn, description: "Turns another user into a vampire if you are a vampire. Costs 25 litres of blood." do |event|
        next if event.channel.id == 83917313761378304
        user_id = get_user_id event
        author = get_user event.message.author.id
        user = get_user user_id
        if author.is_vampire?
          if author.blood_amount >= 25
            if !user.is_vampire?
              author.update(blood_amount: author.blood_amount - 25)
              user.update(is_vampire: true, creator_id: event.message.author.id)
              "**<@#{event.message.author.id}> bites the neck of <@#{user_id}>. After a long period of darkness <@#{user_id}> awakens, fully transformed into a vampire.**"
            else
              "**Nothing happenes.**"
            end
          else
            "You do not have enough blood to transform this person."
          end
        else
          "**<@#{user_id}> turns around <@#{user_id}>**"
        end
      end

      command :bloodbank, description: "Checks the current blood amount in the bank" do
        next if event.channel.id == 83917313761378304
        bank = get_bank
        "The bank currently holds #{bank.blood_amount} litres of blood."
      end

    end
  end
end

def get_user_id(event)
  event.message.mentions.blank? ? event.message.author.id : event.message.mentions.first.id
end

class Vampire
  include Mongoid::Document

  field :user_id,       type: String
  field :creator_id,    type: String, default: nil
  field :blood_amount,  type: Float, default: 0
  field :is_vampire,    type: Boolean, default: false
end

class Bloodbank
  include Mongoid::Document

  field :blood_amount,  type: Float, default: 0
  field :donors,        type: Array, default: []
end

def get_bank
  begin
    if Bloodbank.all.count < 1
      bank = Bloodbank.create
    else
      bank = Bloodbank.all.first
    end
  rescue  Mongoid::Errors::DocumentNotFound => e
    puts e.message
  end
  return bank unless bank.blank?
end

def get_user(user_id)
  begin
    return user = Vampire.find_or_create_by(user_id: user_id)
  rescue  Mongoid::Errors::DocumentNotFound => e
    puts e.message
  end
end
