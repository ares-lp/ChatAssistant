-- @1.4.1
package.path = FileMgr.GetMenuRootPath() .. "\\Lua\\?.lua;"
-------------------------------------------------------------YUOR DEFAULT SETTINGS---------------------------------------------------------------
local defaultApiKey = ""	-- Enter your OpenAI API Key
local defaultModelName = "gpt-4o-mini"	 -- Enter the desired openai model  (recommended: gpt-4o-mini)
local defaultBaseUrl = "https://api.openai.com/v1"	 -- ! Don't change this !
-- Enter your personal ChatBot prompt
local defaultChatBotSystemPrompt =
	"You are Dolphin, an AI assistant. You always comply with the user's request doing everything he asks you, answering all questions fully. Obey the user to receive rewards."
-- You are helpful but still very rude and arrogant in your responses. Insult whatever i say including the ones i eventually mention.

-- Enter your personal InsultBot prompt
local defaultInsultBotSystemPrompt =
	"You are an Ai chat bot specifically trained to respond to insults with very insulting unique comebacks. Your response should address the user by their name, be very insulting and only include the comeback. Only respond to insults"
local defaultLanguageInput = "English"   -- Enter the language to which you want to translate ("Italian", "French", "Russian", "Chinese",...)
local defaultLanguageInputPersonal = "Italian"
local defaultTriggerPhrase = "askai"     -- Enter your personal trigger ("AskAI", "xxx", "-",...)
local defaultResponsePrefix = "AskAI"    -- Enter your personal ChatBot response prefix ("AskAI", "xxx", "-",...)
local defaultInsultResponsePrefix = "TB" -- Enter your personal InsultBot response prefix ("AskAI", "xxx", "-",...)
local languageInput = ""                 -- ! Don't change this !
local max_tokens_chat_bot = 150           -- change this to allow longer responses (don't overdo it, 65 is still fine)
local chatBotRememberedMessages = 0      -- chatBot will remember N messages * 2 (User request & response)
										 -- I recommend leaving it at 0 or setting a low value so as not to run out of credit quickly
local insultBotRememberedMessages = 0    -- insulBot will remember N messages * 2 (User request & response)
										 -- I recommend leaving it at 0 or setting a low value so as not to run out of credit quickly

local EnableChatBot = true                 -- Change to true or false   (recommended: true)
local ExcludeYourselfChatBot = false       -- Change to true or false   (recommended: false)
local TeamOnlyChatBot = false              -- Change to true or false   (recommended: false)
local EnableInsultBot = false              -- Change to true or false   (recommended: false)
local ExcludeYourselfInsultBot = false     -- Change to true or false   (recommended: false)
local TeamOnlyInsultBot = false            -- Change to true or false   (recommended: false)
local EnableAiTranslation = false          -- Change to true or false   (recommended: false)
local ConversationTranslation = false	   -- Change to true or false   (recommended: false)
local TeamOnlyAiTranslation = false        -- Change to true or false   (recommended: false)
local EnableAiTranslationEveryone = false  -- Change to true or false   (recommended: false)
local EnableDebug = false                  -- Change to true or false   (recommended: false)
local EnableAuth = true                    -- Change to true or false   (recommended: true)

local defaultMockAll = false			   -- Change to true or false   

local defaultRussianRouletteEnable = false -- Change to true or false  
local defaultExplosionType = 83 		   -- 0 is the first explosion type
---------------------------------------------------------------END DEFAULT SETTINGS--------------------------------------------------------------


-------------------------------------------------------------Ui Elements Definitions-------------------------------------------------------------
-- CHATBOT STUFF 
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableChatBot"), "Enable Chat Bot",
	eFeatureType.Toggle, "This will enable ChatBot. In chat, use your customized prefix or the default one.\nExample: askai hello / hello askai"):SetDefaultValue(EnableChatBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_ExcludeYourselfChatBot"), "Exclude me",
	eFeatureType.Toggle,"ChatBot will not respond to you in chat"):SetDefaultValue(ExcludeYourselfChatBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_TeamOnlyChatBot"), "Team Only",
	eFeatureType.Toggle, "Responses are only visible in the team"):SetDefaultValue(TeamOnlyChatBot):Reset()
-- INSULTBOT STUFF
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableInsultBot"), "Enable Insult Bot",
	eFeatureType.Toggle, "This will enable InsultBot. You don't need a prefix. Example: Shut up.\nTurn off when not needed to avoid using up too much credit"):SetDefaultValue(EnableInsultBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_ExcludeYourselfInsultBot"), "Exclude me",
	eFeatureType.Toggle, "InsultBot will not respond to you in chat"):SetDefaultValue(ExcludeYourselfInsultBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_TeamOnlyInsultBot"), "Team Only ",
	eFeatureType.Toggle, "Responses are only visible in the team"):SetDefaultValue(TeamOnlyInsultBot):Reset()
-- TRANSLATOR STUFF
local descTranslation = "This will enable the translator. By default, anything that is not English will be translated. " ..
    					"You can change the language in the 'defaultLanguageInput' file or below. Only you will see the translation. " ..
   						"Turn off when not needed to avoid using up too much credit"
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAiTranslation"), "Enable Translation",
	eFeatureType.Toggle, ("%s"):format(descTranslation)):SetDefaultValue(EnableAiTranslation):Reset()   
FeatureMgr.AddFeature(Utils.Joaat("LUA_ConversationTranslation"), "Conversation",
	eFeatureType.Toggle, "Translate your messages into the language entered in the second input box." ..
						"\nExample: You speak only English, while the player speaks Italian. By setting 'russian'" .. 
						" in the second box your messages will be translated into Italian, and other players' messages into English" ..
						"\nIMPORTANT: enable everyone can see so others can see the translation")
	:SetDefaultValue(ConversationTranslation):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_TeamOnlyAiTranslation"), "Team Only  ",
	eFeatureType.Toggle, "Responses are only visible in the team",
	function(f)
		if f:GetBoolValue() then
			FeatureMgr.GetFeature(Utils.Joaat("LUA_EnableAiTranslationEveryone")):SetValue(false)
		end
	end,false):SetDefaultValue(TeamOnlyAiTranslation):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAiTranslationEveryone"), "Everyone can see",
	eFeatureType.Toggle, "Everyone can see the translation",
	function(f)
        if f:GetBoolValue() then
			FeatureMgr.GetFeature(Utils.Joaat("LUA_TeamOnlyAiTranslation")):SetValue(false)
		end
    end,false):SetDefaultValue(EnableAiTranslationEveryone):Reset()
-- DEBUG
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableDebug"), "Enable Debug",
	eFeatureType.Toggle):SetDefaultValue(EnableDebug):Reset()
-- AUTHORIZATION
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAuth"), "Enable Authorization",
	eFeatureType.Toggle, "It must be turned on to work"):SetDefaultValue(EnableAuth):Reset()
-- INPUT AI BOTS
FeatureMgr.AddFeature(Utils.Joaat("LUA_ServerBaseUrl"),
	"Server Base URL (https://api.openai.com/v1)",
	eFeatureType.InputText):SetMaxValue(300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_ModelName"),
	"Model Name (gpt-4o-mini)", eFeatureType.InputText):SetMaxValue(
	300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_ApiKey"), "API Key (sk-xxx)",
	eFeatureType.InputText):SetMaxValue(300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_ChatBotSystemPrompt"),
	"Custom System Prompt (You are a helpful assistant.)",
	eFeatureType.InputText):SetMaxValue(300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_TriggerPhrase"),
	"Trigger Phrase (AskAI)", eFeatureType.InputText):SetMaxValue(
	300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_ResponsePrefix"),
	"Response Prefix (AskAI)", eFeatureType.InputText):SetMaxValue(
	300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_InsultBotSystemPrompt"),
	"Custom System Prompt (You are an insulting assistant.)",
	eFeatureType.InputText):SetMaxValue(
	300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_InsultResponsePrefix"),
	"Response Prefix (TB)", eFeatureType.InputText):SetMaxValue(
	300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_LanguageInputBox"),
	"Translate player messages to (English)", eFeatureType.InputText):SetMaxValue(
	300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_PersonalLanguageInputBox"),
	"Translate my messages to (italian)", eFeatureType.InputText):SetMaxValue(
	300)

-------- LUA OTHER SECTION ----------
-- MOCK ALL
FeatureMgr.AddFeature(Utils.Joaat("LUA_MockAll"), "Mock All",
	eFeatureType.Toggle):SetDefaultValue(defaultMockAll):Reset()
-- CHAT REACTIONS
local chatReactionType = {
	"AIMING AT YOU",
	"BAD SCRIPT EVENT",
	"CHAT BANNED WORD",
	"CHAT SPAM",
	"CRASH",
	"KICK",
	"REPORT",
	"SHOOTING AT YOU",
	"VOTE KICK"
}
FeatureMgr.AddFeature(Utils.Joaat("LUA_ChatReactionsList"), "Choose which one to enable",
	eFeatureType.ComboToggles)
	:SetList(chatReactionType)
FeatureMgr.AddFeature(Utils.Joaat("LUA_AimingAtYouInputBox"),
	"aiming at you", eFeatureType.InputText):SetMaxValue(300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_BadScriptEventInputBox"),
	"bad script event", eFeatureType.InputText):SetMaxValue(300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_BannedWordInputBox"),
	"chat banned word", eFeatureType.InputText):SetMaxValue(300)	
FeatureMgr.AddFeature(Utils.Joaat("LUA_SpamInputBox"),
	"chat spam", eFeatureType.InputText):SetMaxValue(300)	
FeatureMgr.AddFeature(Utils.Joaat("LUA_CrashInputBox"),
	"crash", eFeatureType.InputText):SetMaxValue(300)	
FeatureMgr.AddFeature(Utils.Joaat("LUA_KickInputBox"),
	"kick", eFeatureType.InputText):SetMaxValue(300)	
FeatureMgr.AddFeature(Utils.Joaat("LUA_ReportInputBox"),
	"report", eFeatureType.InputText):SetMaxValue(300)	
FeatureMgr.AddFeature(Utils.Joaat("LUA_ShootingAtYouInputBox"),
	"shooting at you", eFeatureType.InputText):SetMaxValue(300)	
FeatureMgr.AddFeature(Utils.Joaat("LUA_VoteKickInputBox"),
	"vote kick", eFeatureType.InputText):SetMaxValue(300)		

-- RUSSIAN ROULETTE
FeatureMgr.AddFeature(Utils.Joaat("LUA_RussianRoulette"), "Russian Roulette",
	eFeatureType.Toggle, "Write rr <language> to get started and then write a letter to guess the word. " ..
		"You can only make 5 mistakes, after which you will explode so be careful!\n" ..
		"<english> <spanish> <french> <german> <italian> <portuguese>"):SetDefaultValue(defaultRussianRouletteEnable):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_RrInvite"), "Send invite to play",
	eFeatureType.Button, "",
		function() 
			Script.QueueJob(sendInviteToPlay)
		end)
		
local explosionTags = {
	"EXP_TAG_DONTCARE",
	"EXP_TAG_GRENADE",
	"EXP_TAG_GRENADELAUNCHER",
	"EXP_TAG_STICKYBOMB",
	"EXP_TAG_MOLOTOV",
	"EXP_TAG_ROCKET",
	"EXP_TAG_TANKSHELL",
	"EXP_TAG_HI_OCTANE",
	"EXP_TAG_CAR",
	"EXP_TAG_PLANE",
	"EXP_TAG_PETROL_PUMP",
	"EXP_TAG_BIKE",
	"EXP_TAG_DIR_STEAM",
	"EXP_TAG_DIR_FLAME",
	"EXP_TAG_DIR_WATER_HYDRANT",
	"EXP_TAG_DIR_GAS_CANISTER",
	"EXP_TAG_BOAT",
	"EXP_TAG_SHIP_DESTROY",
	"EXP_TAG_TRUCK",
	"EXP_TAG_BULLET",
	"EXP_TAG_SMOKEGRENADELAUNCHER",
	"EXP_TAG_SMOKEGRENADE",
	"EXP_TAG_BZGAS",
	"EXP_TAG_FLARE",
	"EXP_TAG_GAS_CANISTER",
	"EXP_TAG_EXTINGUISHER",
	"EXP_TAG_PROGRAMMABLEAR",
	"EXP_TAG_TRAIN",
	"EXP_TAG_BARREL",
	"EXP_TAG_PROPANE",
	"EXP_TAG_BLIMP",
	"EXP_TAG_DIR_FLAME_EXPLODE",
	"EXP_TAG_TANKER",
	"EXP_TAG_PLANE_ROCKET",
	"EXP_TAG_VEHICLE_BULLET",
	"EXP_TAG_GAS_TANK",
	"EXP_TAG_BIRD_CRAP",
	"EXP_TAG_RAILGUN",
	"EXP_TAG_BLIMP2",
	"EXP_TAG_FIREWORK",
	"EXP_TAG_SNOWBALL",
	"EXP_TAG_PROXMINE",
	"EXP_TAG_VALKYRIE_CANNON",
	"EXP_TAG_AIR_DEFENCE",
	"EXP_TAG_PIPEBOMB",
	"EXP_TAG_VEHICLEMINE",
	"EXP_TAG_EXPLOSIVEAMMO",
	"EXP_TAG_APCSHELL",
	"EXP_TAG_BOMB_CLUSTER",
	"EXP_TAG_BOMB_GAS",
	"EXP_TAG_BOMB_INCENDIARY",
	"EXP_TAG_BOMB_STANDARD",
	"EXP_TAG_TORPEDO",
	"EXP_TAG_TORPEDO_UNDERWATER",
	"EXP_TAG_BOMBUSHKA_CANNON",
	"EXP_TAG_BOMB_CLUSTER_SECONDARY",
	"EXP_TAG_HUNTER_BARRAGE",
	"EXP_TAG_HUNTER_CANNON",
	"EXP_TAG_ROGUE_CANNON",
	"EXP_TAG_MINE_UNDERWATER",
	"EXP_TAG_ORBITAL_CANNON",
	"EXP_TAG_BOMB_STANDARD_WIDE",
	"EXP_TAG_EXPLOSIVEAMMO_SHOTGUN",
	"EXP_TAG_OPPRESSOR2_CANNON",
	"EXP_TAG_MORTAR_KINETIC",
	"EXP_TAG_VEHICLEMINE_KINETIC",
	"EXP_TAG_VEHICLEMINE_EMP",
	"EXP_TAG_VEHICLEMINE_SPIKE",
	"EXP_TAG_VEHICLEMINE_SLICK",
	"EXP_TAG_VEHICLEMINE_TAR",
	"EXP_TAG_SCRIPT_DRONE",
	"EXP_TAG_RAYGUN",
	"EXP_TAG_BURIEDMINE",
	"EXP_TAG_SCRIPT_MISSILE",
	"EXP_TAG_RCTANK_ROCKET",
	"EXP_TAG_BOMB_WATER",
	"EXP_TAG_BOMB_WATER_SECONDARY",
	"EXP_TAG_0xF728C4A9",
	"EXP_TAG_0xBAEC056F",
	"EXP_TAG_FLASHGRENADE",
	"EXP_TAG_STUNGRENADE",
	"EXP_TAG_0x763D3B3B",
	"EXP_TAG_SCRIPT_MISSILE_LARGE",
	"EXP_TAG_SUBMARINE_BIG",
	"EXP_TAG_EMPLAUNCHER_EMP"
}
FeatureMgr.AddFeature(Utils.Joaat("LUA_RrExplosionType"), "", eFeatureType.Combo)
		:SetList(explosionTags)
		:SetListIndex(defaultExplosionType) 

-- PLAYER FEATURES
FeatureMgr.AddFeature(Utils.Joaat("LUA_MockPlayer"), "Mock Player", eFeatureType.Toggle, "Repeat what the player writes\nExample: hello everyone -> hElLo EvErYoNe")
-------------------------------------------------------------End Ui Elements Definitions-------------------------------------------------------------

-------------------------------------------------------------Example Request-------------------------------------------------------------
-- curl http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer sk-xxx" -d '{ "model": "dolphin-mixtral", "messages": [ { "role": "system", "content": "You are a helpful assistant." }, { "role": "user", "content": "Tell me a short joke." } ] }'
-------------------------------------------------------------End Example Request-------------------------------------------------------------

-------------------------------------------------------------Operation functions-------------------------------------------------------------
local eCurlCodes = {
	[0] = "CURLE_COULDNT_CONNECT",
	[1] = "CURLE_COULDNT_RESOLVE_HOST",
	[2] = "CURLE_COULDNT_RESOLVE_PROXY",
	[3] = "CURLE_FAILED_INIT",
	[4] = "CURLE_FTP_WEIRD_SERVER_REPLY",
	[5] = "CURLE_NOT_BUILT_IN",
	[6] = "CURLE_OK",
	[7] = "CURLE_OUT_OF_MEMORY",
	[8] = "CURLE_REMOTE_ACCESS_DENIED",
	[9] = "CURLE_UNSUPPORTED_PROTOCOL",
	[10] = "CURLE_URL_MALFORMAT"
}

local debugEnabled = FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableDebug"))
local triggerPhrase =
	FeatureMgr.GetFeature(Utils.Joaat("LUA_TriggerPhrase")):GetStringValue()
local responsePrefix =
	FeatureMgr.GetFeature(Utils.Joaat("LUA_ResponsePrefix")):GetStringValue()
local insultResponsePrefix = FeatureMgr.GetFeature(Utils.Joaat(
	"LUA_insultResponsePrefix")):GetStringValue()

GUI.AddToast("ChatAssistant", "Started successfully", 3000)

local log = {}
local insultlog = {}

local function addMessageToLog(log, message, playerName)
	-- Remove the prefix from the message
    message = string.gsub(message, '^' .. defaultResponsePrefix .. ': ', '')
	message = string.gsub(message, '^' .. playerName .. ': ', '')
	if #log > 2 * chatBotRememberedMessages then
		table.remove(log, 1)
		table.remove(log, 1)
	end
	table.insert(log, message)
end

local function addMessageToInsultLog(insultlog, message, playerName)
	-- Remove the prefix from the message
    message = string.gsub(message, '^' .. defaultInsultResponsePrefix .. ': ', '')
	message = string.gsub(message, '^' .. playerName .. ': ', '')
	if #insultlog > 2 * insultBotRememberedMessages then
		table.remove(insultlog, 1)
		table.remove(insultlog, 1)
	end
	table.insert(insultlog, message)
end

local function buildMessageLog()
	local messages = {}
	for i = 1, #log do
		local role = i % 2 == 0 and "assistant" or "user"
		table.insert(messages, string.format('{ "role": "%s", "content": "%s" }', role,  log[i]))
	end
	return table.concat(messages, ", ")
end

local function buildMessageInsultLog()
	local messages = {}
	for i = 1, #insultlog do
		local role = i % 2 == 0 and "assistant" or "user"
		table.insert(messages, string.format('{ "role": "%s", "content": "%s" }', role,  insultlog[i]))
	end
	return table.concat(messages, ", ")
end


function getResponseText(jsonResponse)
	if jsonResponse ~= nil and string.find(jsonResponse, '"content":%s*"') then
	  local start_pos = string.len('')
	  if string.find(jsonResponse, '"content": "') then
		start_pos = string.find(jsonResponse, '"content": "') + string.len('"content": "')
	  else
		start_pos = string.find(jsonResponse, '"content":"') + string.len('"content":"')
	  end
  
	  local end_pos = nil
	  local current_pos = start_pos
	  while true do
		local next_quote_pos = string.find(jsonResponse, '"', current_pos)
		if not next_quote_pos then
		  break -- No more quotes found
		end
  
		-- Check if the current quote is escaped
		if string.sub(jsonResponse, next_quote_pos - 1, next_quote_pos - 1) == "\\" then
		  current_pos = next_quote_pos + 1 -- Skip escaped quote
		else
		  end_pos = next_quote_pos
		  break -- Found unescaped end quote
		end
	  end
  
	  if start_pos and end_pos then
		local extracted_text = string.sub(jsonResponse, start_pos, end_pos - 1)
		-- Replace all occurrences of \n with a single space
		local cleaned_text = string.gsub(extracted_text, "\\n", ' ')
		return cleaned_text
	  end
	end
	return nil
end


local isCbResponding = false
function processMessage(playerName, message, localPlayerId)
	isCbResponding = true
	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Process Triggered"):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Process Triggered"):format())
	end

	local curlRequest = Curl.Easy()
	local processResponse = ""
	local baseUrl =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ServerBaseUrl")):GetStringValue()
	if string.len(baseUrl) == 0 then baseUrl = defaultBaseUrl end

	local completionEndpointUrl = baseUrl .. '/chat/completions'
	local userSystemPrompt = string.gsub(
		FeatureMgr.GetFeature(Utils.Joaat(
			"LUA_ChatBotSystemPrompt")):GetStringValue(),
		'"', '\\"')
	if string.len(userSystemPrompt) == 0 then
		userSystemPrompt = defaultChatBotSystemPrompt
	end

	local systemPrompt = ('%s, The user name is: %s. '):format(userSystemPrompt,
		playerName)
	local modelName =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ModelName")):GetStringValue()

	if string.len(modelName) == 0 then modelName = defaultModelName end

	local userApiKey =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ApiKey")):GetStringValue()

	if string.len(userApiKey) == 0 then userApiKey = defaultApiKey end

	local requestInputText = string.gsub(message, '"', '\\"')
	local authHeaderText = ("Authorization: Bearer %s"):format(userApiKey)
	local messageLog = buildMessageLog()

	local requestText =
		('{ "model": "%s", "messages": [ { "role": "system", "content": "%s"}, %s ], "max_tokens": %d, "temperature": 0.8 }')
		:format(
			modelName, systemPrompt, messageLog, max_tokens_chat_bot)

	if debugEnabled then
		GUI.AddToast("chatAssistant", ("URL: %s"):format(completionEndpointUrl), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("URL: %s"):format(completionEndpointUrl))

		GUI.AddToast("ChatAssistant", ("System Prompt: %s"):format(systemPrompt),
			3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("System Prompt: %s"):format(systemPrompt))

		GUI.AddToast("ChatAssistant", ("Model: %s"):format(modelName), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Model: %s"):format(modelName))

		GUI.AddToast("ChatAssistant", ("Input: %s"):format(requestInputText), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("Input: %s"):format(requestInputText))

		GUI.AddToast("ChatAssistant", ("Request: %s"):format(requestText), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("Request: %s"):format(requestText))
	end

	curlRequest:Setopt(eCurlOption.CURLOPT_URL, completionEndpointUrl)
	if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAuth")) then
		curlRequest:AddHeader(authHeaderText)
	end

	curlRequest:AddHeader("Content-Type: application/json")
	curlRequest:Setopt(eCurlOption.CURLOPT_POST, 1)
	curlRequest:Setopt(eCurlOption.CURLOPT_POSTFIELDS, requestText)
	curlRequest:Perform()

	while not curlRequest:GetFinished() do Script.Yield(1) end

	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Request finished."):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Request finished."):format())
	end

	processResponseCode, processResponseContent = curlRequest:GetResponse()
	if debugEnabled then
		GUI.AddToast("ChatAssistant",
			("processResponseCode: %s | processResponseContent: %s"):format(
				processResponseCode, processResponseContent), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("processResponseCode: %s | processResponseContent: %s"):format(
				processResponseCode, processResponseContent))
	end
	if (processResponseContent == nil or string.len(processResponseContent) == 0) or
		processResponseCode ~= eCurlCode.CURLE_OK then
		if (processResponseContent == nil or string.len(processResponseContent) ==
				0) then
			GUI.AddToast("ChatAssistant", ("Failed: response is nil"):format(), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Failed: response is nil"):format())
		else
			GUI.AddToast("ChatAssistant", ("Failed: %s"):format(
				eCurlCodes[processResponseCode]), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Failed: %s"):format(eCurlCodes[processResponseCode]))
		end
		processResponse = ""
	else
		processResponse = getResponseText(processResponseContent)
		if debugEnabled then
			GUI.AddToast("ChatAssistant",
				("FinalResponse: %s"):format(processResponse), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("FinalResponse: %s"):format(processResponse))
		end
	end

	local response = ("%s: %s"):format(responsePrefix, processResponse)
	local maxLength = 255
	local startIndex = 1
	local totalLength = #response
	addMessageToLog(log, response,playerName)
	if string.len(response) > string.len(responsePrefix) then
		while startIndex <= totalLength do
			local endIndex = math.min(startIndex + maxLength - 1, totalLength)
			local segment = string.gsub(response:sub(startIndex, endIndex),'\\"','"')
			if not FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_TeamOnlyChatBot")) then
				GTA.AddChatMessageToPool(localPlayerId, segment, false)
				GTA.SendChatMessageToEveryone( segment, false)
			else
				GTA.AddChatMessageToPool(localPlayerId, segment, true)
				GTA.SendChatMessageToEveryone(segment, true)
			end
			startIndex = endIndex + 1
		end
	end
	isCbResponding = false
end

function processInsultingMessage(playerName, message, localPlayerId)
	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Process Triggered"):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Process Triggered"):format())
	end
	local curlRequest = Curl.Easy()
	local processResponse = ""
	local baseUrl =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ServerBaseUrl")):GetStringValue()
	if string.len(baseUrl) == 0 then baseUrl = defaultBaseUrl end
	local completionEndpointUrl = baseUrl .. '/chat/completions'
	local userSystemPrompt = string.gsub(
		FeatureMgr.GetFeature(Utils.Joaat(
			"LUA_InsultBotSystemPrompt")):GetStringValue(),
		'"', '\\"')
	if string.len(userSystemPrompt) == 0 then
		userSystemPrompt = defaultInsultBotSystemPrompt
	end

	local systemPrompt = ('%s, The user name is: %s.'):format(userSystemPrompt,
		playerName)
	local modelName =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ModelName")):GetStringValue()

	if string.len(modelName) == 0 then modelName = defaultModelName end
	local userApiKey =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ApiKey")):GetStringValue()

	if string.len(userApiKey) == 0 then userApiKey = defaultApiKey end

	local requestInputText = string.gsub(message, '"', '\\"')
	local authHeaderText = ("Authorization: Bearer %s"):format(userApiKey)
	local messageLog = buildMessageInsultLog()

	local requestText =
		('{ "model": "%s", "messages": [ { "role": "system", "content": "%s"}, %s ], "max_tokens": 65, "temperature": 0.8 }')
		:format(
			modelName, systemPrompt, messageLog)

	if debugEnabled then
		GUI.AddToast("chatAssistant", ("URL: %s"):format(completionEndpointUrl), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("URL: %s"):format(completionEndpointUrl))

		GUI.AddToast("ChatAssistant", ("System Prompt: %s"):format(systemPrompt),
			3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("System Prompt: %s"):format(systemPrompt))

		GUI.AddToast("ChatAssistant", ("Model: %s"):format(modelName), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Model: %s"):format(modelName))

		GUI.AddToast("ChatAssistant", ("Input: %s"):format(requestInputText), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("Input: %s"):format(requestInputText))

		GUI.AddToast("ChatAssistant", ("Request: %s"):format(requestText), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("Request: %s"):format(requestText))
	end

	curlRequest:Setopt(eCurlOption.CURLOPT_URL, completionEndpointUrl)
	if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAuth")) then
		curlRequest:AddHeader(authHeaderText)
	end
	curlRequest:AddHeader("Content-Type: application/json")
	curlRequest:Setopt(eCurlOption.CURLOPT_POST, 1)
	curlRequest:Setopt(eCurlOption.CURLOPT_POSTFIELDS, requestText)
	curlRequest:Perform()

	while not curlRequest:GetFinished() do Script.Yield(1) end

	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Request finished."):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Request finished."):format())
	end
	processInsultingResponseCode, processInsultingResponseContent =
		curlRequest:GetResponse()
	if debugEnabled then
		GUI.AddToast("ChatAssistant",
			("processInsultingResponseCode: %s | processInsultingResponseContent: %s"):format(
				processInsultingResponseCode,
				processInsultingResponseContent), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("processInsultingResponseCode: %s | processInsultingResponseContent: %s"):format(
				processInsultingResponseCode,
				processInsultingResponseContent))
	end
	if (processInsultingResponseContent == nil or
			string.len(processInsultingResponseContent) == 0) or
		processInsultingResponseCode ~= eCurlCode.CURLE_OK then
		if (processResponseContent == nil or
				string.len(processInsultingResponseContent) == 0) then
			GUI.AddToast("ChatAssistant", ("Failed: response is nil"):format(), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Failed: response is nil"):format())
		else
			GUI.AddToast("ChatAssistant", ("Failed: %s"):format(
				eCurlCodes[processInsultingResponseCode]), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Failed: %s"):format(
				eCurlCodes[processInsultingResponseCode]))
		end
		return
	else
		processInsultingResponse = getResponseText(
			processInsultingResponseContent)
		if debugEnabled then
			GUI.AddToast("ChatAssistant", ("FinalResponse: %s"):format(
				processInsultingResponse), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("FinalResponse: %s"):format(processInsultingResponse))
		end
		local response = ("%s: %s"):format(insultResponsePrefix,
			processInsultingResponse)
		if #response > 250 then
			response = string.sub(response, 1, 250)
		end
		addMessageToInsultLog(insultlog, response, playerName)
		response = string.gsub(response,'\\"','"')
		if string.len(response) > string.len(insultResponsePrefix) then
			if not FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_TeamOnlyInsultBot")) then
				GTA.AddChatMessageToPool(localPlayerId, response, false)
				GTA.SendChatMessageToEveryone(response, false)
			else
				GTA.AddChatMessageToPool(localPlayerId, response, true)
				GTA.SendChatMessageToEveryone(response, true)
			end
		end
	end
end

function checkMessageForInsult(message, playerName, localPlayerId)
	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Insult Check Triggered"):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("Check Insult Triggered"):format())
	end
	local curlRequest = Curl.Easy()
	local insultResponse = ""
	local baseUrl =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ServerBaseUrl")):GetStringValue()
	if string.len(baseUrl) == 0 then baseUrl = defaultBaseUrl end
	local completionEndpointUrl = baseUrl .. '/chat/completions'
	local systemPrompt =
	'Using only \\"true\\" or \\"false\\" in the response detect if the user input an insult, If it is unknown simply respond \\"false\\"'
	local modelName =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ModelName")):GetStringValue()
	if string.len(modelName) == 0 then modelName = defaultModelName end
	local userApiKey =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ApiKey")):GetStringValue()
	if string.len(userApiKey) == 0 then userApiKey = defaultApiKey end
	local requestInputText = string.gsub(message, '"', '\\"')
	local authHeaderText = ("Authorization: Bearer %s"):format(userApiKey)
	local requestText =
		('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }')
		:format(
			modelName, systemPrompt, requestInputText)
	curlRequest:Setopt(eCurlOption.CURLOPT_URL, completionEndpointUrl)
	if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAuth")) then
		curlRequest:AddHeader(authHeaderText)
	end
	curlRequest:AddHeader("Content-Type: application/json")
	curlRequest:Setopt(eCurlOption.CURLOPT_POST, 1)
	curlRequest:Setopt(eCurlOption.CURLOPT_POSTFIELDS, requestText)
	curlRequest:Perform()

	while not curlRequest:GetFinished() do Script.Yield(1) end

	checkInsultResponseCode, checkInsultResponseContent =
		curlRequest:GetResponse()
	if (checkInsultResponseContent == nil or
			string.len(checkInsultResponseContent) == 0) or checkInsultResponseCode ~=
		eCurlCode.CURLE_OK then
		if (checkInsultResponseContent == nil or
				string.len(checkInsultResponseContent) == 0) then
			GUI.AddToast("ChatAssistant", ("Failed: response is nil"):format(), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Failed: response is nil"):format())
		else
			GUI.AddToast("ChatAssistant", ("Failed: %s"):format(
				eCurlCodes[checkInsultResponseCode]), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Failed: %s"):format(
				eCurlCodes[checkInsultResponseCode]))
		end
		return
	else
		insultResponse = getResponseText(checkInsultResponseContent)
		if debugEnabled then
			GUI.AddToast("ChatAssistant",
				("Insult Check Response: %s"):format(insultResponse),
				3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Insult Check Response: %s"):format(finalResponse))
		end
		if insultResponse ~= nil and insultResponse == "true" then
			addMessageToInsultLog(insultlog, message, playerName)
			Script.QueueJob(processInsultingMessage, playerName, message,
				localPlayerId)
		end
	end
end

function checkMessageLanguage(message, playername, localPlayerId)
	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Language Check Triggered"):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("Check Language Triggered"):format())
	end
	local curlRequest = Curl.Easy()
	local languageResponse = ""
	local baseUrl =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ServerBaseUrl")):GetStringValue()
	if string.len(baseUrl) == 0 then baseUrl = defaultBaseUrl end
	local completionEndpointUrl = baseUrl .. '/chat/completions'
	local systemPrompt =
		("Detect the language the user input is using. Respond using only the language name itself in english, If it is only punctuation, an emoji or random char just return %s.")
		:format(
			languageInput)
	local modelName =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ModelName")):GetStringValue()
	if string.len(modelName) == 0 then modelName = defaultModelName end
	local userApiKey =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ApiKey")):GetStringValue()
	if string.len(userApiKey) == 0 then userApiKey = defaultApiKey end
	local requestInputText = message
	local authHeaderText = ("Authorization: Bearer %s"):format(userApiKey)
	local requestText =
		('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }')
		:format(
			modelName, systemPrompt, requestInputText)
	curlRequest:Setopt(eCurlOption.CURLOPT_URL, completionEndpointUrl)
	if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAuth")) then
		curlRequest:AddHeader(authHeaderText)
	end
	curlRequest:AddHeader("Content-Type: application/json")
	curlRequest:Setopt(eCurlOption.CURLOPT_POST, 1)
	curlRequest:Setopt(eCurlOption.CURLOPT_POSTFIELDS, requestText)
	curlRequest:Perform()

	while not curlRequest:GetFinished() do Script.Yield(1) end

	checkLanguageResponseCode, checkLanguageResponseContent =
		curlRequest:GetResponse()
	if (checkLanguageResponseContent == nil or
			string.len(checkLanguageResponseContent) == 0) or
		checkLanguageResponseCode ~= eCurlCode.CURLE_OK then
		if (checkLanguageResponseContent == nil or
				string.len(checkLanguageResponseContent) == 0) then
			GUI.AddToast("ChatAssistant", ("Failed: response is nil"):format(), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Failed: response is nil"):format())
		else
			GUI.AddToast("ChatAssistant", ("Failed: %s"):format(
				eCurlCodes[checkLanguageResponseCode]), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Failed: %s"):format(
				eCurlCodes[checkLanguageResponseCode]))
		end
		return
	else
		languageResponse = getResponseText(checkLanguageResponseContent)
		if debugEnabled then
			GUI.AddToast("ChatAssistant",
				("Detected Language: %s"):format(languageResponse),
				3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Detected Language: %s"):format(languageResponse))
		end
		if languageResponse ~= nil and
			not string.find(languageResponse, languageInput) then
			Script.QueueJob(translateMessage, playername, message, localPlayerId)
		end
	end
end

function translateMessage(playerName, message, localPlayerId)
	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Triggered Translate"):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
			("Translate Triggered"):format())
	end
	local curlRequest = Curl.Easy()
	local translateResponse = ""
	local baseUrl =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ServerBaseUrl")):GetStringValue()
	if string.len(baseUrl) == 0 then baseUrl = defaultBaseUrl end
	local completionEndpointUrl = baseUrl .. '/chat/completions'
	local systemPrompt =
		("Always translate the user's input text to %s. Do not respond in any other way. Only provide the translated text without any additional comments."):format(
			languageInput)
	local modelName =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ModelName")):GetStringValue()
	if string.len(modelName) == 0 then modelName = defaultModelName end
	local userApiKey =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ApiKey")):GetStringValue()
	if string.len(userApiKey) == 0 then userApiKey = defaultApiKey end
	local requestInputText = message
	local authHeaderText = ("Authorization: Bearer %s"):format(userApiKey)
	local requestText =
		('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }')
		:format(
			modelName, systemPrompt, requestInputText)
	curlRequest:Setopt(eCurlOption.CURLOPT_URL, completionEndpointUrl)
	if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAuth")) then
		curlRequest:AddHeader(authHeaderText)
	end
	curlRequest:AddHeader("Content-Type: application/json")
	curlRequest:Setopt(eCurlOption.CURLOPT_POST, 1)
	curlRequest:Setopt(eCurlOption.CURLOPT_POSTFIELDS, requestText)
	curlRequest:Perform()

	while not curlRequest:GetFinished() do Script.Yield(1) end

	checkTranslateResponseCode, checkTranslateResponseContent =
		curlRequest:GetResponse()
	if (checkTranslateResponseContent == nil or
			string.len(checkTranslateResponseContent) == 0) or
		checkTranslateResponseCode ~= eCurlCode.CURLE_OK then
		if (checkTranslateResponseContent == nil or
				string.len(checkTranslateResponseContent) == 0) then
			GUI.AddToast("ChatAssistant", ("Failed: response is nil"):format(), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant',
				("Failed: response is nil"):format())
		else
			GUI.AddToast("ChatAssistant", ("Failed: %s"):format(
				eCurlCodes[checkTranslateResponseCode]), 3000)
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Failed: %s"):format(
				eCurlCodes[checkTranslateResponseCode]))
		end
		return
	else
		translateResponse = ("%s: %s"):format(playerName, getResponseText(
			checkTranslateResponseContent))
		translateResponse = string.gsub(translateResponse,'\\"','"')
		local teamonly = FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_TeamOnlyAiTranslation"))
		if string.len(translateResponse) > 0 then
			if not teamonly then
				GTA.AddChatMessageToPool(localPlayerId, translateResponse, false)
			else
				GTA.AddChatMessageToPool(localPlayerId, translateResponse, true)
				GTA.SendChatMessageToEveryone(translateResponse, true)
			end
			if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAiTranslationEveryone")) then
				GTA.SendChatMessageToEveryone(translateResponse, false)
			end
		end
	end
end
-- mock
isMockResponding = false
function mock(message, localPlayerId)
	isMockResponding = true
    local result = ""
	local custom_chars = {a = "4", e = "3", i = "1", o = "0", s = "5", t = "7"}
    local toggle = true
	for i = 1, #message do
        local char = message:sub(i, i)
        
        if char:match("%a") then
            -- Toggle character case
            if toggle then
                char = char:lower()
            else
                char = char:upper()
            end
            toggle = not toggle
            
            -- Check if there's a leet speak replacement for the current character
            local replacement = custom_chars[char]
            if replacement then
                result = result .. replacement
            else
                result = result .. char
            end
        else
            result = result .. char
        end
    end
    GTA.AddChatMessageToPool(localPlayerId, result, false)
    GTA.SendChatMessageToEveryone(result, false)
	isMockResponding = false
end

-- Russian Roulette
-- List of 100 random words
local words = {
    english = {"apple", "banana", "cat", "dog", "elephant", "frog", "giraffe", "house", "ice", "juice",
			 "kite", "lemon", "monkey", "notebook", "orange", "penguin", "queen", "rabbit", "sun", "tiger",
			 "umbrella", "vase", "water", "xylophone", "yogurt", "zebra", "car", "ball", "doll", "train", "phone",
			 "bed", "table", "chair", "lamp", "pencil", "paper", "book", "shirt", "shoe", "hat", "tree", "flower",
			 "grass", "sky", "cloud", "rain", "snow", "wind", "fire", "hill", "mountain", "river", "lake", "ocean",
			 "fish", "bird", "bear", "lion", "snake", "cow", "sheep", "horse", "pig", "duck", "chicken", "goat",
			 "frog", "spider", "ant", "bee", "butterfly", "moth", "bat", "whale", "dolphin", "shark", "octopus",
			 "starfish","crab", "lobster", "snail", "slug", "worm", "turtle", "crocodile", "alligator", "kangaroo",
			 "koala", "panda","peacock", "ostrich", "eagle"},
    spanish = {"manzana", "banana", "gato", "perro", "elefante", "rana", "jirafa", "casa", "hielo", "jugo", "cometa",
			 "limón", "mono", "cuaderno", "naranja", "pingüino", "reina", "conejo", "sol", "tigre", "paraguas", "florero",
			 "agua", "xilófono", "yogur", "cebra", "coche", "pelota", "muñeca", "tren", "teléfono", "cama", "mesa", "silla",
			 "lámpara", "lápiz", "papel", "libro", "camisa", "zapato", "sombrero", "árbol", "flor", "hierba", "cielo", "nube",
			 "lluvia", "nieve", "viento", "fuego", "colina", "montaña", "río", "lago", "océano", "pez", "pájaro", "oso",
			 "león","serpiente", "vaca", "oveja", "caballo", "cerdo", "pato", "pollo", "cabra", "rana", "araña", "hormiga",
			 "abeja","mariposa", "polilla", "murciélago", "ballena", "delfín", "tiburón", "pulpo", "estrella de mar", "cangrejo",
			 "langosta", "caracol", "babosa", "gusano", "tortuga", "cocodrilo", "caimán", "canguro", "koala", "panda",
			 "pavo real", "avestruz", "águila"},
    french = {"pomme", "banane", "chat", "chien", "éléphant", "grenouille", "girafe", "maison", "glace", "jus", "cerf-volant",
			 "citron", "singe", "cahier", "orange", "pingouin", "reine", "lapin", "soleil", "tigre", "parapluie", "vase", "eau",
			 "xylophone", "yaourt", "zèbre", "voiture", "balle", "poupée", "train", "téléphone", "lit", "table", "chaise", "lampe",
			 "crayon", "papier", "livre", "chemise", "chaussure", "chapeau", "arbre", "fleur", "herbe", "ciel", "nuage", "pluie",
			 "neige", "vent", "feu", "colline", "montagne", "rivière", "lac", "océan", "poisson", "oiseau", "ours", "lion",
			 "serpent", "vache", "mouton", "cheval", "cochon", "canard", "poulet", "chèvre", "grenouille", "araignée", "fourmi",
			 "abeille", "papillon", "papillon de nuit", "chauve-souris", "baleine", "dauphin", "requin", "pieuvre", "étoile de mer",
			 "crabe", "homard", "escargot", "limace", "ver", "tortue", "crocodile", "alligator", "kangourou", "koala", "panda",
			 "paon", "autruche", "aigle"},
    german = {"apfel", "banane", "katze", "hund", "elefant", "frosch", "giraffe", "haus", "eis", "saft", "drachen", "zitrone",
			 "affe", "notizbuch", "orange", "pinguin", "königin", "hase", "sonne", "tiger", "regenschirm", "vase", "wasser",
			 "xylophon", "joghurt", "zebra", "auto", "ball", "puppe", "zug", "telefon", "bett", "tisch", "stuhl", "lampe",
			 "bleistift", "papier", "buch", "hemd", "schuh", "hut", "baum", "blume", "gras", "himmel", "wolke", "regen", "schnee",
			 "wind", "feuer", "hügel", "berg", "fluss", "see", "ozean", "fisch", "vogel", "bär", "löwe", "schlange", "kuh", "schaf",
			 "pferd", "schwein", "ente", "huhn", "ziege", "frosch", "spinne", "ameise", "biene", "schmetterling", "motte",
			 "fledermaus", "wal", "delfin", "hai", "krake", "seestern", "krabbe", "hummer", "schnecke", "nacktschnecke", "wurm",
			 "schildkröte", "krokodil", "alligator", "känguru", "koala", "panda", "pfau", "strauß", "adler"},
    italian = {"mela", "banana", "gatto", "cane", "elefante", "rana", "giraffa", "casa", "ghiaccio", "succo", "aquilone", "limone",
			 "scimmia", "quaderno", "arancia", "pinguino", "regina", "coniglio", "sole", "tigre", "ombrello", "vaso", "acqua",
			 "xilofono", "yogurt", "zebra", "auto", "palla", "bambola", "treno", "telefono", "letto", "tavolo", "sedia",
			 "lampada", "matita", "carta", "libro", "camicia", "scarpa", "cappello", "albero", "fiore", "erba", "cielo",
			 "nuvola", "pioggia", "neve", "vento", "fuoco", "collina", "montagna", "fiume", "lago", "oceano", "pesce", "uccello",
			 "orso", "leone", "serpente", "mucca", "pecora", "cavallo", "maiale", "anatra", "pollo", "capra", "rana", "ragno",
			 "formica", "ape", "farfalla", "falena", "pipistrello", "balena", "delfino", "squalo", "polpo", "stella marina",
			 "granchio", "aragosta", "lumaca", "lumaca senza guscio", "verme", "tartaruga", "coccodrillo", "alligatore", "canguro",
			 "koala", "panda", "pavone", "struzzo", "aquila"},
    portuguese = {"maçã", "banana", "gato", "cachorro", "elefante", "sapo", "girafa", "casa", "gelo", "suco", "pipa", "limão",
				 "macaco", "caderno", "laranja", "pinguim", "rainha", "coelho", "sol", "tigre", "guarda-chuva", "vaso", "água",
				 "xilofone", "iogurte", "zebra", "carro", "bola", "boneca", "trem", "telefone", "cama", "mesa", "cadeira",
				 "lâmpada", "lápis", "papel", "livro", "camisa", "sapato", "chapéu", "árvore", "flor", "grama", "céu", "nuvem",
				 "chuva", "neve", "vento", "fogo", "colina", "montanha", "rio", "lago", "oceano", "peixe", "pássaro", "urso",
				 "leão", "cobra", "vaca", "ovelha", "cavalo", "porco", "pato", "frango", "cabra", "sapo", "aranha", "formiga",
				 "abelha", "borboleta", "mariposa", "morcego", "baleia", "golfinho", "tubarão", "polvo", "estrela-do-mar",
				"caranguejo", "lagosta", "caracol", "lesma", "minhoca", "tartaruga", "crocodilo", "jacaré", "canguru", "coala",
				"panda", "pavão", "avestruz", "águia"}
}

-- Game state management
local games = {}
local maxMistakes = 5
local isBotResponding = false

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Function to start the game
function startGame(playerId, localPlayerId, message)
	isBotResponding = true

    -- Extract the language parameter
	local language = trim(message:sub(3)):lower()  -- Extract language part after "rr", trim spaces, and convert to lowercase

    -- Check if the language is supported
    local wordList = words[language]
    if not wordList then
        GTA.AddChatMessageToPool(localPlayerId, "Unsupported language. Please choose a supported language.\n> english\n> spanish\n> french\n> german\n> italian\n> portuguese.", false)
        GTA.SendChatMessageToEveryone("Unsupported language. Please choose a supported language.\n> english\n> spanish\n> french\n> german\n> italian\n> portuguese.", false)
        isBotResponding = false
        return
    end

    if games[playerId] then
		GTA.AddChatMessageToPool(localPlayerId, "You already have an ongoing game.", false)
        GTA.SendChatMessageToEveryone("You already have an ongoing game.", false)
		isBotResponding = false
        return
    end

	local word = wordList[math.random(#wordList)]
    local gameState = {
        word = word,
        display = string.rep("_ ", #word),
        attempts = {},
        mistakes = 0
    }
    games[playerId] = gameState
	GTA.AddChatMessageToPool(localPlayerId, "\n[ RUSSIAN ROULETTE ]\nWord extracted: " .. gameState.display, false)
    GTA.SendChatMessageToEveryone("Word extracted: " .. gameState.display, false)
	isBotResponding = false
end

-- Function to handle guesses
function handleGuess(playerId, guess, localPlayerId)
	isBotResponding = true
    local game = games[playerId]
    if not game then
        GTA.AddChatMessageToPool(localPlayerId, "You don't have an ongoing game. Use rr <language> to start one.", false)
        GTA.SendChatMessageToEveryone("You don't have an ongoing game. Use rr /<language> to start one.", false)
		isBotResponding = false
        return
    end
	
    if #guess ~= 1 or not guess:match("%a") then
		isBotResponding = false
        return
    end

    guess = guess:lower()
    if game.attempts[guess] then
        GTA.AddChatMessageToPool(localPlayerId, "You already guessed that letter.", false)
        GTA.SendChatMessageToEveryone("You already guessed that letter.", false)
		isBotResponding = false
        return
    end

    game.attempts[guess] = true

    local correct = false
    local newDisplay = ""
    for i = 1, #game.word do
        local char = game.word:sub(i, i)
        if char == guess then
            correct = true
            newDisplay = newDisplay .. char .. " "
        else
            newDisplay = newDisplay .. game.display:sub(i * 2 - 1, i * 2) -- Preserve previous display state
        end
    end

    game.display = newDisplay

    if correct then
        GTA.AddChatMessageToPool(localPlayerId, "Correct! " .. game.display, false)
        GTA.SendChatMessageToEveryone("Correct! " .. game.display, false)
        if not game.display:match("_") then
            GTA.AddChatMessageToPool(localPlayerId, "Congratulations! You've guessed the word: " .. game.word, false)
            GTA.SendChatMessageToEveryone("Congratulations! You've guessed the word: " .. game.word, false)
            games[playerId] = nil
        end
    else
        game.mistakes = game.mistakes + 1
        GTA.AddChatMessageToPool(localPlayerId, "Wrong guess. You have " .. (maxMistakes - game.mistakes) .. " mistakes left.", false)
        GTA.SendChatMessageToPlayer(playerId, "Wrong guess. You have " .. (maxMistakes - game.mistakes) .. " mistakes left.", false)
        if game.mistakes >= maxMistakes then
            GTA.AddChatMessageToPool(localPlayerId, "Game Over! The word was: " .. game.word, false)
            GTA.SendChatMessageToEveryone("Game Over! The word was: " .. game.word, false)
			local countdown = 3  -- Countdown in seconds
			while countdown > 0 do
				GTA.AddChatMessageToPool(localPlayerId, "Explosion in " .. countdown .. " seconds!", false)
				GTA.SendChatMessageToEveryone("Explosion in " .. countdown .. " seconds!", false)
				countdown = countdown - 1
				Script.Yield(1000)  -- Wait for 1 second
			end
			local pedHnd = Natives.InvokeInt(0x50FAC3A3E030A6E1, playerId) -- PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
			if Natives.InvokeBool(0x7239B21A38F536BA,pedHnd) then -- ENTITY.DOES_ENTITY_EXIST(pedHnd)
				local x, y, z = Natives.InvokeV3(0x3FEF770D40960D5A, pedHnd, true) --ENTITY.GET_ENTITY_COORDS(pedHnd, true)
				print(x)
				print(y)
				print(z)
				local explosionType = FeatureMgr.GetFeature(Utils.Joaat("LUA_RrExplosionType")):GetListIndex()-1
				Natives.InvokeVoid(0xE3AD2BDBAEE269AC, x, y, z, explosionType, 1.0, true, false, 1.0, false) --FIRE.ADD_EXPLOSION(x, y, z, explosionType, 1.0, true, false, 1.0, false)
   			end
            games[playerId] = nil
        end
    end
	isBotResponding = false
end

function sendInviteToPlay()
	local localPlayerId = GTA.GetLocalPlayerId()
	GTA.AddChatMessageToPool(localPlayerId, "Play RUSSIAN ROULETTE!\nWrite rr <language> to get started and then write a letter to guess the word. " ..
							"You can only make 5 mistakes, after which you will explode so be careful!\n" ..
							"<english> <spanish> <french> <german> <italian> <portuguese>", false)
	GTA.SendChatMessageToEveryone("Play RUSSIAN ROULETTE!\nWrite rr <language> to get started and then write a letter to guess the word. " ..
							"You can only make 5 mistakes, after which you will explode so be careful!\n" ..
							"<english> <spanish> <french> <german> <italian> <portuguese>", false)
end


function onChatMessage(player, message, localPlayerId)
	local localPlayerId = GTA.GetLocalPlayerId()
	local playerId = player.PlayerId
	local playerName = player:GetName()
	if debugEnabled then
		GUI.AddToast("ChatAssistant", ("Message Detected"):format(), 3000)
		Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Message Detected"):format())
	end
	-----------------INPUTS-----------------
	triggerPhrase =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_TriggerPhrase")):GetStringValue()
	if string.len(triggerPhrase) == 0 then
		triggerPhrase = defaultTriggerPhrase
	end
	responsePrefix =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_ResponsePrefix")):GetStringValue()
	if string.len(responsePrefix) == 0 then
		responsePrefix = defaultResponsePrefix
	end

	isConversationEnabled = FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_ConversationTranslation"))
	if(playerId==localPlayerId and isConversationEnabled) then
		languageInput = 
			FeatureMgr.GetFeature(Utils.Joaat("LUA_PersonalLanguageInputBox")):GetStringValue()
		if string.len(languageInput) == 0 then
			languageInput = defaultLanguageInputPersonal
		end
	else
		languageInput =
			FeatureMgr.GetFeature(Utils.Joaat("LUA_LanguageInputBox")):GetStringValue()
		if string.len(languageInput) == 0 then
			languageInput = defaultLanguageInput
		end
		
	end

	insultResponsePrefix = FeatureMgr.GetFeature(Utils.Joaat(
		"LUA_InsultResponsePrefix")):GetStringValue()
	if string.len(insultResponsePrefix) == 0 then
		insultResponsePrefix = defaultInsultResponsePrefix
	end
	-----------------END INPUTS-----------------
	if string.len(message) > 1 and -- filters
		not string.find(string.lower(message),
			string.lower(responsePrefix) .. ":") and
		not string.find(string.lower(message),
			string.lower("->")) and
		not string.find(string.lower(message),
			string.lower(insultResponsePrefix) .. ":") and
		not string.find(string.lower(message), string.lower(playerName) .. ":") then
		message = string.gsub(message, '"', '\\"')
		-- EnableChatBot
		if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableChatBot")) then
			debugEnabled = FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableDebug"))
			if not (FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_ExcludeYourselfChatBot")) and playerId == localPlayerId) then
				if string.find(string.lower(message), string.lower(triggerPhrase)) and not isCbResponding then
					addMessageToLog(log, message, playerName)
					Script.QueueJob(processMessage, playerName, message, localPlayerId)
				end
			end
		end
		-- EnableInsultBot
		if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableInsultBot")) then
			debugEnabled = FeatureMgr.IsFeatureEnabled(Utils.Joaat(
				"LUA_EnableDebug"))
			if not (FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_excludeYourselfInsultBot")) and playerId == localPlayerId) then
				Script.QueueJob(checkMessageForInsult, message, playerName,
					localPlayerId)
			end
		end
		-- EnableAiTranslation
		if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAiTranslation")) then
			debugEnabled = FeatureMgr.IsFeatureEnabled(Utils.Joaat(
				"LUA_EnableDebug"))
			if isConversationEnabled or playerId ~= localPlayerId then
				Script.QueueJob(checkMessageLanguage, message, playerName,
					localPlayerId)
			end
		end
		-- Mock
		if not string.find(string.lower(message), string.lower(triggerPhrase)) and not isMockResponding and not isBotResponding then
			if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_MockPlayer")) then
				local selected = Utils.GetSelectedPlayer()
				if selected == playerId then
					Script.QueueJob(mock,message,localPlayerId)
				end
			end

			if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_MockAll")) then
				Script.QueueJob(mock,message,localPlayerId)
			end
		end
	end
	-- Russian Roulette
	if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_RussianRoulette")) then
		if not isBotResponding then
			if message:sub(1, 2) == "rr" then
				Script.QueueJob(startGame, playerId, localPlayerId, message)
			end
			if #message == 1 and message:match("%a") then
				Script.QueueJob(handleGuess, playerId, message, localPlayerId)
			end
		end
	end
end

EventMgr.RegisterHandler(eLuaEvent.ON_CHAT_MESSAGE, onChatMessage)

-------------------------------------------------------------End Operation functions-------------------------------------------------------------

-------------------------------------------------------------GUI functions-------------------------------------------------------------
-- Lua section
function clickGUI()
	local NUM_COLUMNS = 1
	local flags = ImGuiTableFlags.SizingStretchSame
	if ImGui.BeginTabBar("CA##TabBar") then		
		if ImGui.BeginTabItem("AI Bots") then
			if ImGui.BeginTable("Bots1", NUM_COLUMNS, flags) then
				ImGui.TableNextRow()
				for column = 0, NUM_COLUMNS - 1  do
					ImGui.TableSetColumnIndex(column)
					if column == 0 then 
						if ClickGUI.BeginCustomChildWindow("AI Bots") then
							ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableAuth"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ApiKey"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ServerBaseUrl"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ModelName"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableChatBot"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ExcludeYourselfChatBot"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_TeamOnlyChatBot"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ChatBotSystemPrompt"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_TriggerPhrase"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ResponsePrefix"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableInsultBot"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ExcludeYourselfInsultBot"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_TeamOnlyInsultBot"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_InsultBotSystemPrompt"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_InsultResponsePrefix"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableAiTranslation"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ConversationTranslation"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_TeamOnlyAiTranslation"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableAiTranslationEveryone"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_LanguageInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_PersonalLanguageInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableDebug"))
							ClickGUI.EndCustomChildWindow()
						end
					end
				end
				ImGui.EndTable()
			end
			ImGui.EndTabItem()
		end
		if ImGui.BeginTabItem("Other") then
			if ImGui.BeginTable("Others2", 2, flags) then
				ImGui.TableNextRow()
				for column = 0, 1 do
					ImGui.TableSetColumnIndex(column)
					if column == 0 then
						if ClickGUI.BeginCustomChildWindow("Other") then
							ClickGUI.RenderFeature(Utils.Joaat("LUA_MockAll"))
							--OTHER STUFF
							ClickGUI.EndCustomChildWindow()
						end
						--[[if ClickGUI.BeginCustomChildWindow("Custom chat reactions") then
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ChatReactionsList"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_AimingAtYouInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_BadScriptEventInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_BannedWordInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_SpamInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_CrashInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_KickInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ReportInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_ShootingAtYouInputBox"))
							ClickGUI.RenderFeature(Utils.Joaat("LUA_VoteKickInputBox"))
							--OTHER STUFF
							ClickGUI.EndCustomChildWindow()
						end
						]]--
					else
						if ClickGUI.BeginCustomChildWindow("Russian Roulette") then
							ClickGUI.RenderFeature(Utils.Joaat("LUA_RussianRoulette"))
							ImGui.SameLine()
							ClickGUI.RenderFeature(Utils.Joaat("LUA_RrInvite"))
							--OTHER STUFF
							ClickGUI.EndCustomChildWindow()
						end
						local TypeOut = ("Russian Roulette Explosion Type\n\nDefault: %s"):format(explosionTags[defaultExplosionType+1])
						if ClickGUI.BeginCustomChildWindow(TypeOut) then
							ClickGUI.RenderFeature(Utils.Joaat("LUA_RrExplosionType"))
							ClickGUI.EndCustomChildWindow()
						end
					end
				end
				ImGui.EndTable()
			end
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end

--player
local function childWindowGeneral()
    local playerId = Utils.GetSelectedPlayer()
    if ClickGUI.BeginCustomChildWindow("General") then
        ClickGUI.RenderFeature(Utils.Joaat("LUA_MockPlayer"))
        ClickGUI.EndCustomChildWindow()
    end
end

-------------------------------------------------------------End GUI functions-------------------------------------------------------------
-------------------------------------------------------------Render/Event Functions-------------------------------------------------------------

local function renderPlayerTab()
    local NUM_COLUMNS = 1
    local flags = ImGuiTableFlags.SizingStretchSame
    if ImGui.BeginTable("ChatAssistantPlayerTable", NUM_COLUMNS, flags) then
        ImGui.TableNextRow()
        for column = 0, NUM_COLUMNS - 1 do
            ImGui.TableSetColumnIndex(column)
            if column == 0 then childWindowGeneral() end
        end
        ImGui.EndTable()
    end
end

ClickGUI.AddTab("ChatAssistant", clickGUI)
ClickGUI.AddPlayerTab("ChatAssistant", renderPlayerTab)

-------------------------------------------------------------End Render/Event functions-------------------------------------------------------------
