local function buildLookup(list)
  local lookup = {}
  if not list then
    return lookup
  end

  for _, identifier in ipairs(list) do
    if type(identifier) == "string" then
      lookup[string.lower(identifier)] = true
    end
  end

  return lookup
end

local function hasDiscordIdentifier(playerId)
  for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
    if identifier:sub(1, 8) == "discord:" then
      return true
    end
  end
  return false
end

local allowedLookup = buildLookup(Config and Config.AllowedDiscordIds)
local pendingTokens = {}

local function vecDistance(a, b)
  if not a or not b then
    return nil
  end
  local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function isAuthorized(playerId)
  for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
    if allowedLookup[string.lower(identifier)] then
      return true
    end
  end
  return false
end

local function generateToken()
  return string.format("%08x%08x%08x", math.random(0, 0xffffffff), math.random(0, 0xffffffff), math.random(0, 0xffffffff))
end

local function getPlayerCoords(id)
  local ped = GetPlayerPed(id)
  if not ped or ped == 0 then
    return nil
  end
  local coords = GetEntityCoords(ped)
  if not coords then
    return nil
  end
  return { x = coords.x, y = coords.y, z = coords.z }
end

local function safeCall(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, res = pcall(fn, ...)
  if not ok then return nil end
  return res
end

local function getPlayerState(id)
  local ped = safeCall(GetPlayerPed, id)
  if not ped or ped == 0 then
    return "unknown"
  end

  local dead = safeCall(IsPedFatallyInjured, ped) or safeCall(IsPedDeadOrDying, ped, true)
  if dead then return "dead" end

  if safeCall(IsPedSwimming, ped) or safeCall(IsPedSwimmingUnderWater, ped) then
    return "swimming"
  end

  if safeCall(IsPedInAnyVehicle, ped, false) then
    return "driving"
  end

  local speed = safeCall(GetEntitySpeed, ped) or 0.0
  if speed > 1.5 then
    return "walking"
  end

  return "idle"
end

local function collectPlayers(viewerId)
  local viewerCoords = getPlayerCoords(viewerId)
  local players = {}

  for _, pid in ipairs(GetPlayers()) do
    local numericId = tonumber(pid)
    if numericId then
      local coords = getPlayerCoords(numericId)
      local distance = vecDistance(viewerCoords, coords)
      local ped = safeCall(GetPlayerPed, numericId)
      local health = ped and (safeCall(GetEntityHealth, ped) or 0) or 0
      local armour = ped and (safeCall(GetPedArmour, ped) or 0) or 0

      table.insert(players, {
        id = numericId,
        name = GetPlayerName(pid) or ("ID " .. pid),
        coords = coords,
        distance = distance,
        identifiers = GetPlayerIdentifiers(pid),
        state = getPlayerState(numericId),
        health = health,
        armour = armour
      })
    end
  end

  table.sort(players, function(a, b)
    return a.id < b.id
  end)

  return players
end

RegisterNetEvent("veracity:requestAccess", function()
  local src = source
  if not src then
    return
  end

  if not hasDiscordIdentifier(src) then
    TriggerClientEvent("veracity:authResult", src, false, "No Discord identifier found.")
    return
  end

  local allowed = isAuthorized(src)
  local reason = Config and Config.DenyMessage or "Not authorized."

  if not allowed then
    TriggerClientEvent("veracity:authResult", src, false, reason)
    return
  end

  local token = generateToken()
  pendingTokens[src] = token

  -- Client will only open when the token it stored matches this open event.
  TriggerClientEvent("veracity:authResult", src, true, "", token)
  TriggerClientEvent("veracity:open", src, token)
end)

RegisterNetEvent("veracity:getPlayers", function(clientToken)
  local src = source
  if not src or type(clientToken) ~= "string" then
    return
  end

  if pendingTokens[src] ~= clientToken then
    return
  end

  local players = collectPlayers(src)
  TriggerClientEvent("veracity:playerList", src, players)
end)

AddEventHandler("playerDropped", function()
  local src = source
  if src then
    pendingTokens[src] = nil
  end
end)
