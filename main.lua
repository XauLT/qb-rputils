local QBCore = exports['qb-core']:GetCoreObject()

local Config = {
    Webhooks = {
        enabled = true,
        me_command = {
            enabled = true,
            webhook_url = "YOUR_WEBHOOK"
        },
        do_command = {
            enabled = true, 
            webhook_url = "YOUR_WEBHOOK"
        }
    },
    LogSettings = {
        log_player_ip = true,
        max_log_length = 500
    }
}


RegisterNetEvent('qb-rputils:client:display', function(type, message, fullName, serverId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(serverId))
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    
    if #(playerCoords - targetCoords) < 35.0 then
        -- Elegant Chat Message
        local chatColors = {
            me = '#3498db',   -- Soft Blue
            others = '#2ecc71'    -- Soft Green
        }

        TriggerEvent('chat:addMessage', {
            template = '<div style="' ..
                'background: rgba(0,0,0,0.6);' ..
                'border-left: 4px solid {1};' ..
                'padding: 8px;' ..
                'margin: 5px;' ..
                'border-radius: 4px;' ..
                'color: white;' ..
                'font-family: Roboto, Arial;' ..
                'font-weight: 300;">{0}</div>',
            args = { 
                type == 'me' and 
                    string.format("( %s ): %s", fullName, message) or 
                    string.format("( %s ): %s", fullName, message),
                chatColors[type == 'do' and 'others' or type] or '#95a5a6'
            }
        })
        
        CreateThread(function()
            local displayTime = 5000
            local startTime = GetGameTimer()
            
            while GetGameTimer() - startTime < displayTime do
                local currentTargetPed = GetPlayerPed(GetPlayerFromServerId(serverId))
                local currentPlayerPed = PlayerPedId()
                local currentPlayerCoords = GetEntityCoords(currentPlayerPed)
                local currentTargetCoords = GetEntityCoords(currentTargetPed)
                
                if #(currentPlayerCoords - currentTargetCoords) < 35.0 then
                    local textCoords = vector3(
                        currentTargetCoords.x, 
                        currentTargetCoords.y, 
                        currentTargetCoords.z + (type == 'me' and 1.0 or 1.2)
                    )
                    
                    Draw3DTextElegant(
                        textCoords, 
                        type == 'me' and 
                            message or 
                            string.format("%s", message),
                        type
                    )
                end
                
                Wait(0)
            end
        end)
    end
end)

RegisterNetEvent('chat:clear', function()
    -- Clear only the calling user's chat
    SendNUIMessage({
        type = 'clear'
    })
end)

function Draw3DTextElegant(coords, text, type)
    local camCoord = GetGameplayCamCoords()
    local distance = #(coords - camCoord)
    local scale = math.max(0.4, math.min(1 / distance * 50, 1.2))

    -- Advanced Color Palette
    local colors = {
        me = {
            text = {r = 52, g = 152, b = 219, a = 255},     -- Blue
            shadow = {r = 41, g = 128, b = 185, a = 200}   -- Dark Blue
        },
        others = {
            text = {r = 46, g = 204, b = 113, a = 255},     -- Green
            shadow = {r = 39, g = 174, b = 96, a = 200}    -- Dark Green
        }
    }

    local selectedColor = colors[type == 'do' and 'others' or type] or colors.me

    -- Text Settings
    SetTextFont(8)
    SetTextScale(0.35 * scale, 0.35 * scale)  
    SetTextColour(
        selectedColor.text.r, 
        selectedColor.text.g, 
        selectedColor.text.b, 
        selectedColor.text.a
    )
    SetTextDropshadow(
        3, 
        selectedColor.shadow.r, 
        selectedColor.shadow.g, 
        selectedColor.shadow.b, 
        selectedColor.shadow.a
    )
    SetTextCentre(true)

    SetTextEntry("STRING")
    AddTextComponentString(text)

    local onScreen, worldX, worldY = World3dToScreen2d(coords.x, coords.y, coords.z)
    
    if onScreen then
        DrawText(worldX, worldY)
    end
end

-- Helper Lerp Function
function Lerp(a, b, t)
    return a + (b - a) * t
end

-- Server-Side Section
function SendDiscordLog(type, player, message)
    -- Config check
    if not Config.Webhooks.enabled then return end
    
    local webhookConfig = type == 'me' 
        and Config.Webhooks.me_command 
        or Config.Webhooks.do_command

    if not webhookConfig.enabled then return end

    -- Limit log length
    message = message:sub(1, Config.LogSettings.max_log_length or 1000)

    local embed = {
        {
            ["color"] = type == 'me' and 3447003 or 3066993,
            ["title"] = type == 'me' and "ME Command Used" or "DO Command Used",
            ["description"] = message,
            ["fields"] = {
                {
                    ["name"] = "Player Information",
                    ["value"] = string.format("**Name:** %s\n**ID:** %s", player.fullName, player.source)
                }
            },
            ["footer"] = {
                ["text"] = os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }

    -- Optional details
    if Config.LogSettings.log_player_ip then
        table.insert(embed[1].fields, {
            ["name"] = "IP Address",
            ["value"] = GetPlayerEndpoint(player.source) or "Unknown"
        })
    end

    PerformHttpRequest(webhookConfig.webhook_url, function(err, text, headers) 
        -- Only Errors
        if err ~= 200 and err ~= 204 then
            print(string.format("[WEBHOOK ERROR] Code: %d, Text: %s", err, tostring(text)))
        end
    end, 'POST', json.encode({embeds = embed}), { 
        ['Content-Type'] = 'application/json' 
    })
end


if IsDuplicityVersion() then
    QBCore.Commands.Add('me', 'Perform an action', {{name = 'action', help = 'Action'}}, false, function(source, args)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local fullName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        
        if #args > 0 then
            local message = table.concat(args, " ")
            
            local playerInfo = {
                source = src,
                fullName = fullName
            }

            -- Send log to Discord
            SendDiscordLog('me', playerInfo, message)
            
            TriggerClientEvent('qb-rputils:client:display', -1, 'me', message, fullName, src)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Please enter an action', 'error')
        end
    end)

    QBCore.Commands.Add('do', 'Describe a situation', {{name = 'situation', help = 'Situation'}}, false, function(source, args)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local fullName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        
        if #args > 0 then
            local message = table.concat(args, " ")
            
            local playerInfo = {
                source = src,
                fullName = fullName
            }

            -- Send log to Discord
            SendDiscordLog('do', playerInfo, message)
            
            TriggerClientEvent('qb-rputils:client:display', -1, 'do', message, fullName, src)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Please enter a situation', 'error')
        end
    end)
	
	QBCore.Commands.Add('clearchat', 'Clear your chat screen', {}, false, function(source)
		TriggerClientEvent('chat:clear', source)
		TriggerClientEvent('QBCore:Notify', source, 'Your chat screen has been cleared.', 'inform')
	end)
end