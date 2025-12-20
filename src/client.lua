local uiOpen = false

local function setUI(state)
  uiOpen = state
  SetNuiFocus(state, state)
  SetNuiFocusKeepInput(state)

  SendNUIMessage({
    type = "setVisible",
    visible = state
  })
end

RegisterCommand("veracity", function()
  setUI(not uiOpen)
end, false)
RegisterCommand("vrc", function()
  setUI(not uiOpen)
end, false)

RegisterNUICallback("close", function(_, cb)
  setUI(false)
  cb("ok")
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
