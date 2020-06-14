local discordia = require("discordia")
local games = require("Games")
local misc = require("Misc")
local client = discordia.Client()

discordia.extensions() -- load all helpful extensions

--#############################################################################################################################################
--# Settings                                                                                                                                  #
--#############################################################################################################################################

LOG_MOTTBOT_MESSAGES = true

local currentGhostChannel = nil
local currentGhostFriend = nil

--#############################################################################################################################################
--# Specific Games                                                                                                                            #
--# ANYTHING THAT NEEDS TO BE EDITED TO ADD A NEW GAME GOES HERE                                                                              #
--#############################################################################################################################################

local werewords = require("Werewords")
local tictactoe = require("TicTacToe")
local medium = require("Medium")
local curios = require("Curios")
local letterjam = require("LetterJam")
local fastlength = require("Fastlength")
local codenames = require("Codenames")
local chameleon = require("Chameleon")

-- {Name : {Description, Rules, StartFunction, CommandHandler}}
GAME_LIST = {
	Werewords = {
		desc = [[A social deduction game for 4-10 players. One player picks a secret word, and the other players ask them yes or no questions to try to deduce it. Certain players are secretly werewolves, and trying to prevent the word from being guessed.]], 
		rules = [[http://werewords.com/rules.php?ver=2]], 
		startFunc = werewords.startGame,
		handler = werewords.commandHandler,
		dmHandler = werewords.dmHandler
	},
	TicTacToe = {
		desc = [[It's literally Tic-Tac-Toe.]],
		rules = [[How old are you that you don't know how to play Tic-Tac-Toe?]],
		startFunc = tictactoe.startGame,
		handler = tictactoe.commandHandler,
		dmHandler = tictactoe.dmHandler
	},
	Medium = {
		desc = [[A mind reading game for 2-8 players. Players take turns picking two words from a hand of cards, and trying to find a word that most relates to the two they picked, without communicating at all. Use of ESP is highly encouraged.]],
		rules = [[https://stormchasergames.files.wordpress.com/2019/06/medium-rulebook-final-reduced-size-1.pdf]],
		startFunc = medium.startGame,
		handler = medium.commandHandler,
		dmHandler = medium.dmHandler
	},
	Curios = {
		desc = [[A bluffing game for 2-5 players. Players are dealt a hand of cards, providing partial information about the value of differently colored gems; each turn, everyone attempts to make the most money placing workers to acquire gems.]],
		rules = [[https://www.alderac.com/wp-content/uploads/2019/04/Curio_Rulebook_Final-Feb2019.pdf]],
		startFunc = curios.startGame,
		handler = curios.commandHandler,
		dmHandler = curios.dmHandler
	},
	LetterJam = {
		desc = [[A cooperative word game for 2+ players. Players each have a letter that only they can't see. Players take turns spelling words with the letters that they can see, thus helping people guess their own letter.]],
		rules = [[https://czechgames.com/files/rules/letter-jam-rules-en.pdf]],
		startFunc = letterjam.startGame,
		handler = letterjam.commandHandler,
		dmHandler = letterjam.dmHandler
	},
	Fastlength = {
		desc = [[An implementation of exactly one round of Wavelength. One player is given a card with an axis on it, and a position on that axis, from -10 to 10. Their goal is to say a word that other players will place at roughly that position on the axis.]],
		rules = [[https://www.ultraboardgames.com/wavelength/game-rules.php but with no scoring]],
		startFunc = fastlength.startGame,
		handler = fastlength.commandHandler,
		dmHandler = fastlength.dmHandler
	},
	Codenames = {
		desc = [[A team-based word game for 4-8 players. Each team has a secret list of words, and one spymaster, whose goal is to get their teammates to pick their words, without picking the opposing team's words.]],
		rules = [[https://czechgames.com/files/rules/codenames-rules-en.pdf]],
		startFunc = codenames.startGame,
		handler = codenames.commandHandler,
		dmHandler = codenames.dmHandler
	},
	Chameleon = {
		desc = [[A social deduction word game for 3+ players. All players are given the same word in secret, except for the Chameleon, who must try to blend in -- at least until they figure out what the word is.]],
		rules = [[https://bigpotato.com/blog/how-to-play-the-chameleon-instructions/]],
		startFunc = chameleon.startGame,
		handler = chameleon.commandHandler,
		dmHandler = chameleon.dmHandler
	}
}

function initGames()
	--[[Called when the bot initializes]]
	-- Currently empty; werewords.loadWordlists() was originally called here, but that made it inaccessible to Werewords.lua, for reasons I don't 
	-- fully understand
end

function gameCommands(message)
	--[[Called on new messages]]
	local content = message.content
	local channel = message.channel
	local author = message.author
	local args = content:split(" ")

	if misc.keyInTable(channel, games.INSTANCES) then -- Channel has game already
		-- Run game-specific functions
		local gameType = games.INSTANCES[channel][2]
		local state = games.INSTANCES[channel][3]
		GAME_LIST[gameType].handler(message, state)
	elseif games.playerInGame(author) then -- Player is in a game, call relevant handlers
		-- Check every game to see if the player is playing, and call the relevant event handler for that game
		for channel, game in pairs(games.INSTANCES) do
			for idx, player in pairs(game[4]) do
				if author == player then
					GAME_LIST[game[2]].dmHandler(message, game[3])
				end
			end
		end
	else -- Channel does not have game already
		if args[1] == "!start" then
			local nameOfGame = misc.getKeyInTableInsensitive(args[2], GAME_LIST)
			if nameOfGame then
				-- Call the function associated with the given game
				-- This is ugly as fuck, but it's all worth it to carve a few extra bytes off the filesize of the lua interpreter(???)
				GAME_LIST[nameOfGame].startFunc(message)
			else
				channel:send("Uh-oh! I don't know how to play that game, homie!")
			end
		end
	end
end

--#############################################################################################################################################
--# Command Handlers                                                                                                                          #
--#############################################################################################################################################

function miscCommands(message)
	--[[Miscellaneous functionality goes here]]
	if string.match(message.content, "( ͡° ͜ʖ ͡°)") then
		if string.match(string.lower(message.content), "fast") then
			message.channel:send("( ͡° ͜ʖ ͡°)")
		end
	end
	if message.mentionsEveryone then
		local warning = "DON'T SHAKE THE BABY"
		if message.author.name == "Smogilski" then
			warning = warning .. ", SHAYNE!!!"
		end
		message.channel:send(warning)
	end
end

function logDMs(content, channel, author, args)
	--[[Logs private messages to console (messages from MottBot can be excluded, optionally)]]
	if channel.type == 1 then 
		if args[1] ~= "!echo" and args[1] ~= "!setchannel" then
			if author.name ~= "MottBot" or LOG_MOTTBOT_MESSAGES == true then 
				print(author.name .. ": " .. content)
			end
		end
	end
end

function echoCommands(content, channel, author, args)
	--[[Handles !setchannel and !echo]]
	if args[1] == "!setchannel" then
		local id = args[2]
		currentGhostChannel = client:getChannel(id)
		if currentGhostChannel == nil then
			local user = client:getUser(id)
			currentGhostChannel = user:getPrivateChannel()
			currentGhostFriend = user.name
		else
			currentGhostFriend = nil
		end
		print(currentGhostChannel)
		print(args[2])
	elseif args[1] == "!echo" then
		--print(message.content)
		--channel:send("<@!132092363098030080>")
		local message = ""
		for i, word in pairs(args) do
			if i == 2 then message = word end
			if i > 2 then message = message .. " " .. word end
		end
		if currentGhostChannel ~= nil then currentGhostChannel:send(message) else print("Error: nil channel") end
		if currentGhostFriend ~= nil then print("To: " .. currentGhostFriend .. ": " .. message) end
	end
end

function infoCommands(content, channel, author, args)
	--[[Informational functions]]
	if args[1] == "!games" then -- Print the list of games the bot can run
		local output = ""
		for key,value in pairs(GAME_LIST) do
			output = output .. key .. ": " .. value["desc"] .. "\n"
		end
		channel:send(output)
	elseif args[1] == "!list" then -- Print a list of currently running games
		local noGames = true -- lua's table size operator is notoriously useless
		local output = ""
		for key,value in pairs(games.INSTANCES) do
			noGames = false
			local game = value[1] .. ": " .. value[2]
			output = output .. game .. "\n"
		end
		if noGames then channel:send("No games currently running.") else channel:send(output) end
	elseif args[1] == "!info" then -- Print info about a specific game
		for key,value in pairs(GAME_LIST) do
			if args[2] == key then
				local msg = value["desc"] .. "\nRules: " .. value["rules"]
				channel:send(msg)
			end
		end
	end
end

--#############################################################################################################################################
--# Bot Functions                                                                                                                             #
--#############################################################################################################################################

-- Login
client:on("ready", function()
	print("Logged in as " .. client.user.username)
	initGames()
end)


-- Handle new messages
client:on("messageCreate", function(message)

	local content = message.content
	local channel = message.channel
	local author = message.author
	local args = content:split(" ") -- split all arguments into a table

	logDMs(content, channel, author, args)
	echoCommands(content, channel, author, args)
	infoCommands(content, channel, author, args)
	gameCommands(message) -- Send the entire message, as some games might need additional information (eg mentionedUsers, reactions)
	miscCommands(message)
end)


client:run("Bot NDgzMDk4NjU3OTE5MzM2NDU5.XQxfww.ADyJ_eU5oaITvr_xZRvTcnZcs5s") -- replace BOT_TOKEN with your bot token

--TODO:
--success, checkForEnd
--voting