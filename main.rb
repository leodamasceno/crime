require 'discordrb'
require 'httparty'
require 'yaml'
require 'json'
require 'dotenv/load'

Dotenv.load

bot = Discordrb::Bot.new token: ENV['TOKEN'], client_id: ENV['CLIENT_ID']

queue = Array.new
msg = ""

bot.message(start_with: '!crime queue') do |event|
  type = event.message.to_s.split(' ')
  discord_user = event.user.name
  if type[2] == 'flex' && type[3].nil?
    event.respond "Looking for more players to feed with you..."
    queue_players(discord_user,event.channel,msg,queue)
  elsif type[2] == 'flex' && type[3] == 'remove'
    remove_queue_player(discord_user,queue,event)
  else
    show_queue(queue,msg,event.channel)
  end
end

bot.message(start_with: '!crime build') do |event|
  champion = event.message.to_s.split(' ')
  if champion[2].nil?
    msg = "Specify a champion. Example: !crime build Shaco"
  else
    build = lol_champion_build(champion[2])
    build['data']["#{champion[2]}"]['recommended'].each do |row|
      row['blocks'].each do |value|
        if value['type'] == 'startingjungle'
          puts value['items']
        end
      end
    end
  end
  #event.respond "Status: #{msg}"
end

bot.message(start_with: '!crime status') do |event|
  status = lol_server_status
  if status.empty?
    msg = "Server is up. Go lose some games"
  else
    msg = "Server is down. Go play minecraft"
  end
  event.respond "Status: #{msg}"
end

bot.message(start_with: '!crime elo') do |event|
  summoner = event.message.to_s.split(' ')
  discord_user = event.user.name
  if summoner[2].nil?
    result = lol_get_summoner_elo(lol_summoner_info(discord_user))
    result.each do |elo|
      if elo['queueType'] == 'RANKED_FLEX_SR'
        queue = 'Flex'
      else
        queue = 'Solo/Duo'
      end
      event.respond "#{queue} - #{elo['tier']} - #{elo['rank']}"
    end

  else
    result = lol_get_summoner_elo(lol_summoner_info(summoner[2]))
    result.each do |elo|
      if elo['queueType'] == 'RANKED_FLEX_SR'
        queue = 'Flex'
      else
        queue = 'Solo/Duo'
      end
      event.respond "#{queue} - #{elo['tier']} - #{elo['rank']}"
    end
  end
end

def show_queue(queue,msg,channel)
  if queue.empty?
    msg = "0 players"
  else
    queue.each do |player|
      msg = msg + "- #{player} \n"
    end
  end
  channel.send_embed do |embed|
    embed.title = 'Players in queue'
    embed.description = msg
  end
end

def remove_queue_player(user,queue,event)
  puts "User: #{user}"
  queue.delete user
  event.respond "You have been removed from queue"
end

def queue_players(user,channel,msg,queue)
  if !queue.include? user
    queue.push user
    queue.each do |player|
      msg = msg + "- #{player} \n"
    end
  else
    msg = "0 players"
  end
  channel.send_embed do |embed|
    embed.title = 'Players in queue'
    embed.description = msg
  end
end

def lol_champion_build(champion)
  dd_api_url = "http://ddragon.leagueoflegends.com/cdn/11.3.1/data/en_US/champion/#{champion}.json"
  dd_response = HTTParty.get("#{dd_api_url}")

  json = JSON.parse(dd_response.body)

  return json
  #return dd_response['data']["#{champion}"]['recommended']['champion']
end

def lol_server_status
  server_api_url = "https://euw1.api.riotgames.com/lol/status/v4/platform-data?api_key=RGAPI-7b32b466-23f5-4f14-afa7-9dc28f64bf20"
  server_response = HTTParty.get("#{server_api_url}")

  return server_response['maintenances']

end

def lol_summoner_info(username)
  summoner_api_url = "https://euw1.api.riotgames.com/lol/summoner/v4/summoners/by-name/#{username}?api_key=RGAPI-7b32b466-23f5-4f14-afa7-9dc28f64bf20"
  summoner_response = HTTParty.get("#{summoner_api_url}")

  return summoner_response['id']
end

def lol_get_summoner_elo(id)
  summoner_api_url = "https://euw1.api.riotgames.com/lol/league/v4/entries/by-summoner/#{id}?api_key=RGAPI-7b32b466-23f5-4f14-afa7-9dc28f64bf20"
  summoner_response = HTTParty.get("#{summoner_api_url}")

  return summoner_response
end



bot.run
