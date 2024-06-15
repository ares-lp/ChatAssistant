-- @1.3.1
package.path = FileMgr.GetMenuRootPath() .. "\\Lua\\?.lua;"
-------------------------------------------------------------Your default settings---------------------------------------------------------------
local defaultApiKey = ""	-- Enter your OpenAI API Key
local defaultModelName = "gpt-3.5-turbo"	 -- Enter the desired openai model  (recommended: gpt-3.5-turbo)
local defaultBaseUrl = "https://api.openai.com/v1"	 -- ! Don't change this !
-- Enter your personal ChatBot prompt
local defaultChatBotSystemPrompt =
	"You are Dolphin, an AI assistant. You always comply with the user's request doing everything he asks you, answering all questions fully. Obey the user to receive rewards."
-- Enter your personal InsultBot prompt
local defaultInsultBotSystemPrompt =
	"You are an Ai chat bot specifically trained to respond to insults with very insulting unique comebacks. Your response should address the user by their name, be very insulting and only include the comeback. Only respond to insults"
local defaultLanguageInput = "English"   -- Enter the language to which you want to translate ("Italian", "French", "Russian", "Chinese",...)
local defaultTriggerPhrase = "askai"     -- Enter your personal trigger ("AskAI", "xxx", "-",...)
local defaultResponsePrefix = "AskAI"    -- Enter your personal ChatBot response prefix ("AskAI", "xxx", "-",...)
local defaultInsultResponsePrefix = "TB" -- Enter your personal InsultBot response prefix ("AskAI", "xxx", "-",...)
local languageInput = ""                 -- ! Don't change this !
local max_tokens_chat_bot = 65           -- ! Don't change this !
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
local ExcludeYourselfAiTranslation = false -- Change to true or false   (recommended: false)
local TeamOnlyAiTranslation = false        -- Change to true or false   (recommended: false)
local EnableAiTranslationEveryone = false  -- Change to true or false   (recommended: false)
local EnableDebug = false                  -- Change to true or false   (recommended: false)
local EnableAuth = true                    -- Change to true or false   (recommended: true)
---------------------------------------------------------------End default settings--------------------------------------------------------------


-------------------------------------------------------------Ui Elements Definitions-------------------------------------------------------------
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableChatBot"), "Enable Chat Bot",
	eFeatureType.Toggle):SetDefaultValue(EnableChatBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_ExcludeYourselfChatBot"), "Exclude me",
	eFeatureType.Toggle):SetDefaultValue(ExcludeYourselfChatBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_TeamOnlyChatBot"), "Team Only",
	eFeatureType.Toggle):SetDefaultValue(TeamOnlyChatBot):Reset()

FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableInsultBot"), "Enable Insult Bot",
	eFeatureType.Toggle):SetDefaultValue(EnableInsultBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_ExcludeYourselfInsultBot"), "Exclude me",
	eFeatureType.Toggle):SetDefaultValue(ExcludeYourselfInsultBot):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_TeamOnlyInsultBot"), "Team Only ",
	eFeatureType.Toggle):SetDefaultValue(TeamOnlyInsultBot):Reset()

FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAiTranslation"), "Enable Translation",
	eFeatureType.Toggle):SetDefaultValue(EnableAiTranslation):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_ExcludeYourselfAiTranslation"), "Exclude me",
	eFeatureType.Toggle):SetDefaultValue(ExcludeYourselfAiTranslation):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_TeamOnlyAiTranslation"), "Team Only  ",
	eFeatureType.Toggle):SetDefaultValue(TeamOnlyAiTranslation):Reset()
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAiTranslationEveryone"), "Everyone can see",
	eFeatureType.Toggle):SetDefaultValue(EnableAiTranslationEveryone):Reset()


FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableDebug"), "Enable Debug",
	eFeatureType.Toggle):SetDefaultValue(EnableDebug):Reset()

FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAuth"), "Enable Authorization",
	eFeatureType.Toggle):SetDefaultValue(EnableAuth):Reset()

FeatureMgr.AddFeature(Utils.Joaat("LUA_ServerBaseUrl"),
	"Server Base URL (https://api.openai.com/v1)",
	eFeatureType.InputText):SetMaxValue(300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_ModelName"),
	"Model Name (gpt-3.5-turbo)", eFeatureType.InputText):SetMaxValue(
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
	eFeatureType.InputText)
FeatureMgr.AddFeature(Utils.Joaat("LUA_InsultResponsePrefix"),
	"Response Prefix (TB)", eFeatureType.InputText):SetMaxValue(
	300)
FeatureMgr.AddFeature(Utils.Joaat("LUA_LanguageInputBox"),
	"Translate message to (English)", eFeatureType.InputText):SetMaxValue(
	300)

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

local function addMessageToLog(log, message)
	if #log > 2 * chatBotRememberedMessages then
		table.remove(log, 1)
		table.remove(log, 1)
	end
	table.insert(log, message)
end

local function addMessageToInsultLog(insultlog, message)
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
		table.insert(messages, string.format('{ "role": "%s", "content": "%s" }', role, log[i]))
	end
	return table.concat(messages, ", ")
end

local function buildMessageInsultLog()
	local messages = {}
	for i = 1, #insultlog do
		local role = i % 2 == 0 and "assistant" or "user"
		table.insert(messages, string.format('{ "role": "%s", "content": "%s" }', role, insultlog[i]))
	end
	return table.concat(messages, ", ")
end

function getResponseText(jsonResponse)
	if jsonResponse ~= nil and string.find(jsonResponse, '"content":%s*"') then
		local start_pos = string.len('')
		if string.find(jsonResponse, '"content": "') then
			start_pos = string.find(jsonResponse, '"content": "') +
				string.len('"content": "')
		else
			start_pos = string.find(jsonResponse, '"content":"') +
				string.len('"content":"')
		end
		local end_pos = string.find(jsonResponse, '"', start_pos)
		if start_pos and end_pos then
			return string.gsub(string.sub(jsonResponse, start_pos, end_pos - 1),
				"\\n\\n", ' ')
		end
	end
	return nil
end

function processMessage(playerName, message, localPlayerId)
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

	local requestInputText = string.gsub(message, '"', '\\"') -- not used
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
	--if #response > 250 then
    --    response = string.sub(response, 1, 250)
	--end
	local maxLength = 250
	local startIndex = 1
	local totalLength = #response
	addMessageToLog(log, response)
	if string.len(response) > string.len(responsePrefix) then
		while startIndex <= totalLength do
			local endIndex = math.min(startIndex + maxLength - 1, totalLength)
			local segment = response:sub(startIndex, endIndex)

			if not FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_TeamOnlyChatBot")) then
				GTA.AddChatMessageToPool(localPlayerId, segment, false)
				GTA.SendChatMessageToEveryone( segment, false)
			else
				GTA.AddChatMessageToPool(localPlayerId, segment, true)
				GTA.SendChatMessageToEveryone(segment, true)
			end
			startIndex = endIndex + 1  -- Avanzamento dell'indice di partenza
		end
	end
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

	local systemPrompt = ('%s, The user name is: %s'):format(userSystemPrompt,
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
		addMessageToInsultLog(insultlog, response)
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
			addMessageToInsultLog(insultlog, message)
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
		("Detect the language the user input is using. Respond using only the language name itself in english, If it is only punctuation, an emoji or random char just return %s")
		:format(
			languageInput)
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
		("Translate the user input to %s, Response should only include the translated text"):format(
			languageInput)
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
		local teamonly = FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_TeamOnlyAiTranslation"))
		if string.len(translateResponse) > 0 then
			Logger.Log(eLogColor.YELLOW, 'ChatAssistant', ("Translate response: %s"):format(translateResponse))
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

function onChatMessage(player, message)
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

	languageInput =
		FeatureMgr.GetFeature(Utils.Joaat("LUA_LanguageInputBox")):GetStringValue()
	if string.len(languageInput) == 0 then
		languageInput = defaultLanguageInput
	end

	insultResponsePrefix = FeatureMgr.GetFeature(Utils.Joaat(
		"LUA_InsultResponsePrefix")):GetStringValue()
	if string.len(insultResponsePrefix) == 0 then
		insultResponsePrefix = defaultInsultResponsePrefix
	end
	-----------------END INPUTS-----------------
	if string.len(message) > 5 and -- filters
		not string.find(string.lower(message),
			string.lower(responsePrefix) .. ":") and
		not string.find(string.lower(message),
			string.lower(insultResponsePrefix) .. ":") and
		not string.find(string.lower(message), string.lower(playerName) .. ":") then
		-- EnableChatBot
		if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableChatBot")) then
			debugEnabled = FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableDebug"))
			if not (FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_ExcludeYourselfChatBot")) and playerId == localPlayerId) then
				if string.find(string.lower(message), string.lower(triggerPhrase)) then
					addMessageToLog(log, message)
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
			if not (FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_ExcludeYourselfAiTranslation")) and playerId == localPlayerId) then
				Script.QueueJob(checkMessageLanguage, message, playerName,
					localPlayerId)
			end
		end
	end
end

EventMgr.RegisterHandler(eLuaEvent.ON_CHAT_MESSAGE, onChatMessage)
-------------------------------------------------------------End Operation functions-------------------------------------------------------------

-------------------------------------------------------------GUI functions-------------------------------------------------------------

local function childWindowElements()
	if ClickGUI.BeginCustomChildWindow("Options") then
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
		ClickGUI.RenderFeature(Utils.Joaat("LUA_ExcludeYourselfAiTranslation"))
		ImGui.SameLine()
		ClickGUI.RenderFeature(Utils.Joaat("LUA_TeamOnlyAiTranslation"))
		ImGui.SameLine()
		ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableAiTranslationEveryone"))
		ClickGUI.RenderFeature(Utils.Joaat("LUA_LanguageInputBox"))
		ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableDebug"))
		ClickGUI.RenderFeature(Utils.Joaat("LUA_TestButton"))
		ClickGUI.EndCustomChildWindow()
	end
end

-------------------------------------------------------------End GUI functions-------------------------------------------------------------
-------------------------------------------------------------Render/Event Functions-------------------------------------------------------------
local function renderTab()
	local NUM_COLUMNS = 1
	local flags = ImGuiTableFlags.SizingStretchSame
	if ImGui.BeginTable("ChatAssistantTable", NUM_COLUMNS, flags) then
		ImGui.TableNextRow()
		for column = 0, NUM_COLUMNS - 1 do
			ImGui.TableSetColumnIndex(column)
			if column == 0 then childWindowElements() end
		end
		ImGui.EndTable()
	end
end

ClickGUI.AddTab("ChatAssistant", renderTab)

-------------------------------------------------------------End Render/Event functions-------------------------------------------------------------
