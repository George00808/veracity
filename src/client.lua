local uiOpen = false
local authPending = false
local sessionToken = nil

local function setUI(state)
  uiOpen = state
  SetNuiFocus(state, state)
  SetNuiFocusKeepInput(state)

  SendNUIMessage({
    type = "setVisible",
    visible = state
  })
end

local function notifyDenied(reason)
  local message = reason or "Access denied."
  TriggerEvent('chat:addMessage', { args = { '^1Veracity', message } })
end

RegisterNetEvent('veracity:authResult', function(allowed, reason, token)
  authPending = false

  if not allowed then
    sessionToken = nil
    notifyDenied(reason)
    return
  end

  if type(token) ~= "string" or #token == 0 then
    sessionToken = nil
    notifyDenied("Invalid auth token.")
    return
  end

  sessionToken = token
end)

RegisterNetEvent('veracity:open', function(token)
  if not sessionToken or token ~= sessionToken then
    return -- ignore spoofed or stale attempts
  end

  setUI(true)
end)

RegisterNetEvent('veracity:playerList', function(list)
  if not sessionToken then
    return
  end
  SendNUIMessage({
    type = "players",
    players = list or {}
  })
end)

local function requestAccess()
  if authPending then
    return
  end

  authPending = true
  TriggerServerEvent('veracity:requestAccess')
end

local function requestPlayers()
  if not sessionToken or not uiOpen then
    return
  end
  TriggerServerEvent('veracity:getPlayers', sessionToken)
end

local function toggleUI()
  if uiOpen then
    setUI(false)
    return
  end

  requestAccess()
end

RegisterCommand('veracity', function()
  toggleUI()
end, false)

RegisterCommand('vrc', function()
  toggleUI()
end, false)

RegisterNUICallback('close', function(_, cb)
  setUI(false)
  cb('ok')
end)

RegisterNUICallback('requestPlayers', function(_, cb)
  requestPlayers()
  cb('ok')
end)

CreateThread(function()
  while true do
    local waitTime = uiOpen and 1000 or 500
    if uiOpen then
      requestPlayers()
      DisableControlAction(0, 1, true)
      DisableControlAction(0, 2, true)
      DisableControlAction(0, 24, true)
      DisableControlAction(0, 25, true)
      DisableControlAction(0, 177, true)
      if IsDisabledControlJustReleased(0, 177) then
        setUI(false)
      end
    end
    Wait(waitTime)
  end
end)
