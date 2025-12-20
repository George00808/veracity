local uiOpen = false
local authPending = false
local expectedToken = nil

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
    expectedToken = nil
    notifyDenied(reason)
    return
  end

  if type(token) ~= "string" or #token == 0 then
    expectedToken = nil
    notifyDenied("Invalid auth token.")
    return
  end

  expectedToken = token
end)

RegisterNetEvent('veracity:open', function(token)
  if not expectedToken or token ~= expectedToken then
    return -- ignore spoofed or stale attempts
  end

  expectedToken = nil
  setUI(true)
end)

local function requestAccess()
  if authPending then
    return
  end

  authPending = true
  TriggerServerEvent('veracity:requestAccess')
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

CreateThread(function()
  while true do
    local waitTime = 500
    if uiOpen then
      waitTime = 0
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
