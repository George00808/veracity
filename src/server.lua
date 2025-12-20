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

AddEventHandler("playerDropped", function()
  local src = source
  if src then
    pendingTokens[src] = nil
  end
end)
