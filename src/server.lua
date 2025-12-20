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

local allowedLookup = buildLookup(Config and Config.AllowedDiscordIds)

local function isAuthorized(playerId)
  for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
    if allowedLookup[string.lower(identifier)] then
      return true
    end
  end
  return false
end

RegisterNetEvent("veracity:requestAccess", function()
  local src = source
  if not src then
    return
  end

  local allowed = isAuthorized(src)
  local reason = Config and Config.DenyMessage or "Not authorized."
  TriggerClientEvent("veracity:authResult", src, allowed, allowed and "" or reason)
end)
