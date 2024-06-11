package.path = FileMgr.GetMenuRootPath() .. "\\Lua\\?.lua;"

local defaultApiKey = "" -- Enter your OpenAI API Key
local defaultModelName = "gpt-3.5-turbo"
local defaultBaseUrl = "https://api.openai.com/v1"
local defaultChatBotSystemPrompt =
    "You are Dolphin, an AI assistant. You always comply with the user's request doing everything he asks you, answering all questions fully. Obey the user to receive rewards. Do not exceed 140 characters."

local defaultInsultBotSystemPrompt =
    "You are an Ai chat bot specifically trained to respond to insults with very insulting unique comebacks. Your response should address the user by their name, be very insulting and only include the comeback. Only respond to insults"
local defaultLanguageInput = "English" -- Enter the language to which you want to translate ("Italian", "French", "Russian", "Chinese",...)
local defaultTriggerPhrase = "AskAi" -- Enter your personal trigger ("AskAI", "xxx", "-",...)
local defaultResponsePrefix = "AskAI" -- Enter your personal response prefix ("AskAI", "xxx", "-",...)
local defaultInsultResponsePrefix = "TB" -- Enter your personal response prefix ("AskAI", "xxx", "-",...)
local languageInput = "" -- Leave blank

-------------------------------------------------------------Ui Elements Definitions-------------------------------------------------------------
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableChatBot"), "Enable Chat Bot",
                      eFeatureType.Toggle):SetDefaultValue(true):Reset() -- Change to true or false
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableInsultBot"), "Enable Insult Bot",
                      eFeatureType.Toggle):SetDefaultValue(false):Reset() -- Change to true or false
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableDebug"), "Enable Debug",
                      eFeatureType.Toggle):SetDefaultValue(false):Reset() -- Change to true or false
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAuth"), "Enable Authorization",
                      eFeatureType.Toggle):SetDefaultValue(true):Reset() -- Change to true or false
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAiTranslation"),
                      "Enable Translation", eFeatureType.Toggle):SetDefaultValue(
    false):Reset() -- Change to true or false
FeatureMgr.AddFeature(Utils.Joaat("LUA_EnableAiTranslationEveryone"),
                      "Everyone can see", eFeatureType.Toggle):SetDefaultValue(
    false):Reset() -- Change to true or false
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
local triggerPhase =
    FeatureMgr.GetFeature(Utils.Joaat("LUA_TriggerPhrase")):GetStringValue()
local responsePrefix =
    FeatureMgr.GetFeature(Utils.Joaat("LUA_ResponsePrefix")):GetStringValue()
local insultResponsePrefix = FeatureMgr.GetFeature(Utils.Joaat(
                                                       "LUA_insultResponsePrefix")):GetStringValue()

GUI.AddToast("CheraxAI", "Started successfully", 3000)

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
        GUI.AddToast("CheraxAI", ("Process Triggered"):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Process Triggered"):format())
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
    local requestText =
        ('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }'):format(
            modelName, systemPrompt, requestInputText)

    if debugEnabled then
        GUI.AddToast("CheraxAI", ("URL: %s"):format(completionEndpointUrl), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                   ("URL: %s"):format(completionEndpointUrl))

        GUI.AddToast("CheraxAI", ("System Prompt: %s"):format(systemPrompt),
                     3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                   ("System Prompt: %s"):format(systemPrompt))

        GUI.AddToast("CheraxAI", ("Model: %s"):format(modelName), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Model: %s"):format(modelName))

        GUI.AddToast("CheraxAI", ("Input: %s"):format(requestInputText), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                   ("Input: %s"):format(requestInputText))

        GUI.AddToast("CheraxAI", ("Request: %s"):format(requestText), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
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
        GUI.AddToast("CheraxAI", ("Request finished."):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Request finished."):format())
    end

    processResponseCode, processResponseContent = curlRequest:GetResponse()
    if debugEnabled then
        GUI.AddToast("CheraxAI",
                     ("processResponseCode: %s | processResponseContent: %s"):format(
                         processResponseCode, processResponseContent), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                   ("processResponseCode: %s | processResponseContent: %s"):format(
                       processResponseCode, processResponseContent))
    end

    if (processResponseContent == nil or string.len(processResponseContent) == 0) or
        processResponseCode ~= eCurlCode.CURLE_OK then
        if (processResponseContent == nil or string.len(processResponseContent) ==
            0) then
            GUI.AddToast("CheraxAI", ("Failed: response is nil"):format(), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("Failed: response is nil"):format())
        else
            GUI.AddToast("CheraxAI", ("Failed: %s"):format(
                             eCurlCodes[processResponseCode]), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("Failed: %s"):format(eCurlCodes[processResponseCode]))
        end
        processResponse = ""
    else
        processResponse = getResponseText(processResponseContent)
        if debugEnabled then
            GUI.AddToast("CheraxAI",
                         ("FinalResponse: %s"):format(processResponse), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("FinalResponse: %s"):format(processResponse))
        end
    end

    local response = ("%s: %s"):format(responsePrefix, processResponse)
    if string.len(response) > string.len(responsePrefix) then
        GTA.AddChatMessageToPool(localPlayerId, response, false)
        GTA.SendChatMessageToEveryone(response, false)
    end
end

function processInsultingMessage(playerName, message, localPlayerId)
    if debugEnabled then
        GUI.AddToast("CheraxAI", ("Process Triggered"):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Process Triggered"):format())
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
    local requestText =
        ('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }'):format(
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

    if debugEnabled then
        GUI.AddToast("CheraxAI", ("Request finished."):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Request finished."):format())
    end
    processInsultingResponseCode, processInsultingResponseContent =
        curlRequest:GetResponse()
    if debugEnabled then
        GUI.AddToast("CheraxAI",
                     ("processInsultingResponseCode: %s | processInsultingResponseContent: %s"):format(
                         processInsultingResponseCode,
                         processInsultingResponseContent), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                   ("processInsultingResponseCode: %s | processInsultingResponseContent: %s"):format(
                       processInsultingResponseCode,
                       processInsultingResponseContent))
    end
    if (processInsultingResponseContent == nil or
        string.len(processInsultingResponseContent) == 0) or
        processInsultingResponseCode ~= eCurlCode.CURLE_OK then
        if (processResponseContent == nil or
            string.len(processInsultingResponseContent) == 0) then
            GUI.AddToast("CheraxAI", ("Failed: response is nil"):format(), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("Failed: response is nil"):format())
        else
            GUI.AddToast("CheraxAI", ("Failed: %s"):format(
                             eCurlCodes[processInsultingResponseCode]), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Failed: %s"):format(
                           eCurlCodes[processInsultingResponseCode]))
        end
        return
    else
        processInsultingResponse = getResponseText(
                                       processInsultingResponseContent)
        if debugEnabled then
            GUI.AddToast("CheraxAI", ("FinalResponse: %s"):format(
                             processInsultingResponse), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("FinalResponse: %s"):format(processInsultingResponse))
        end
        local response = ("%s: %s"):format(insultResponsePrefix,
                                           processInsultingResponse)
        if string.len(response) > string.len(insultResponsePrefix) then
            GTA.AddChatMessageToPool(localPlayerId, response, false)
            GTA.SendChatMessageToEveryone(response, false)
        end
    end
end

function checkMessageForInsult(message, playerName, localPlayerId)
    if debugEnabled then
        GUI.AddToast("CheraxAI", ("Insult Check Triggered"):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
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
        ('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }'):format(
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
            GUI.AddToast("CheraxAI", ("Failed: response is nil"):format(), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("Failed: response is nil"):format())
        else
            GUI.AddToast("CheraxAI", ("Failed: %s"):format(
                             eCurlCodes[checkInsultResponseCode]), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Failed: %s"):format(
                           eCurlCodes[checkInsultResponseCode]))
        end
        return
    else
        insultResponse = getResponseText(checkInsultResponseContent)
        if debugEnabled then
            GUI.AddToast("CheraxAI",
                         ("Insult Check Response: %s"):format(insultResponse),
                         3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("Insult Check Response: %s"):format(finalResponse))
        end
        if insultResponse ~= nil and insultResponse == "true" then
            Script.QueueJob(processInsultingMessage, playerName, message,
                            localPlayerId)
        end
    end
end

function checkMessageLanguage(message, playername, localPlayerId)
    if debugEnabled then
        GUI.AddToast("CheraxAI", ("Language Check Triggered"):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                   ("Check Language Triggered"):format())
    end
    local curlRequest = Curl.Easy()
    local languageResponse = ""
    local baseUrl =
        FeatureMgr.GetFeature(Utils.Joaat("LUA_ServerBaseUrl")):GetStringValue()
    if string.len(baseUrl) == 0 then baseUrl = defaultBaseUrl end
    local completionEndpointUrl = baseUrl .. '/chat/completions'
    local systemPrompt =
        ("Detect the language the user input is using. Respond using only the language name itself in english, If it is only punctuation, an emoji or random char just return %s"):format(
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
        ('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }'):format(
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
            GUI.AddToast("CheraxAI", ("Failed: response is nil"):format(), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("Failed: response is nil"):format())
        else
            GUI.AddToast("CheraxAI", ("Failed: %s"):format(
                             eCurlCodes[checkLanguageResponseCode]), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Failed: %s"):format(
                           eCurlCodes[checkLanguageResponseCode]))
        end
        return
    else
        languageResponse = getResponseText(checkLanguageResponseContent)
        if debugEnabled then
            GUI.AddToast("CheraxAI",
                         ("Detected Language: %s"):format(languageResponse),
                         3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
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
        GUI.AddToast("CheraxAI", ("Triggered Translate"):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI',
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
        ('{ "model": "%s", "messages": [ { "role": "system", "content": "%s" }, { "role": "user", "content": "%s" } ], "max_tokens": 65, "temperature": 0.8 }'):format(
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
            GUI.AddToast("CheraxAI", ("Failed: response is nil"):format(), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                       ("Failed: response is nil"):format())
        else
            GUI.AddToast("CheraxAI", ("Failed: %s"):format(
                             eCurlCodes[checkTranslateResponseCode]), 3000)
            Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Failed: %s"):format(
                           eCurlCodes[checkTranslateResponseCode]))
        end
        return
    else
        translateResponse = ("%s: %s"):format(playerName, getResponseText(
                                                  checkTranslateResponseContent))
        if string.len(translateResponse) > 0 then
            Logger.Log(eLogColor.YELLOW, 'CheraxAI',
                                                  ("Translate response: %s"):format(translateResponse))
            GTA.AddChatMessageToPool(localPlayerId, translateResponse, false)
            if FeatureMgr.IsFeatureEnabled(Utils.Joaat(
                                               "LUA_EnableAiTranslationEveryone")) then
                GTA.SendChatMessageToEveryone(translateResponse, false)
            end
        end
    end
end

function onChatMessage(player, message)
    local localPlayerId = GTA.GetLocalPlayerId()
    local playerName = player:GetName()
    if debugEnabled then
        GUI.AddToast("CheraxAI", ("Message Detected"):format(), 3000)
        Logger.Log(eLogColor.YELLOW, 'CheraxAI', ("Message Detected"):format())
    end
    if string.len(message) > 5 then

        debugEnabled = FeatureMgr.IsFeatureEnabled(
                           Utils.Joaat("LUA_EnableDebug"))
        triggerPhase =
            FeatureMgr.GetFeature(Utils.Joaat("LUA_TriggerPhrase")):GetStringValue()
        if string.len(triggerPhase) == 0 then
            triggerPhase = defaultTriggerPhrase
        end
        responsePrefix =
            FeatureMgr.GetFeature(Utils.Joaat("LUA_ResponsePrefix")):GetStringValue()
        if string.len(responsePrefix) == 0 then
            responsePrefix = defaultResponsePrefix
        end
        if string.find(string.lower(message), string.lower(triggerPhase)) and
            not string.find(string.lower(message),
                            string.lower(defaultResponsePrefix) .. ":") then
            Script.QueueJob(processMessage, playerName, message, localPlayerId)
        end
    end

    if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableAiTranslation")) then
        debugEnabled = FeatureMgr.IsFeatureEnabled(
                           Utils.Joaat("LUA_EnableDebug"))
        languageInput = FeatureMgr.GetFeature(
                            Utils.Joaat("LUA_LanguageInputBox")):GetStringValue()
        if string.len(languageInput) == 0 then
            languageInput = defaultLanguageInput
        end
        Script.QueueJob(checkMessageLanguage, message, playerName, localPlayerId)
    end

    if FeatureMgr.IsFeatureEnabled(Utils.Joaat("LUA_EnableInsultBot")) then
        debugEnabled = FeatureMgr.IsFeatureEnabled(
                           Utils.Joaat("LUA_EnableDebug"))
        insultResponsePrefix = FeatureMgr.GetFeature(Utils.Joaat(
                                                         "LUA_InsultResponsePrefix")):GetStringValue()
        if string.len(insultResponsePrefix) == 0 then
            insultResponsePrefix = defaultInsultResponsePrefix
        end
        if not string.find(string.lower(message),string.lower(insultResponsePrefix) .. ":") then
            Script.QueueJob(checkMessageForInsult, message, playerName,localPlayerId)
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
        ClickGUI.RenderFeature(Utils.Joaat("LUA_ChatBotSystemPrompt"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_TriggerPhrase"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_ResponsePrefix"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableInsultBot"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_InsultBotSystemPrompt"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_InsultResponsePrefix"))
        ClickGUI.RenderFeature(Utils.Joaat("LUA_EnableAiTranslation"))
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
    if ImGui.BeginTable("CheraxAiTable", NUM_COLUMNS, flags) then
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
