-- center_limit.lua: Limite de Centros de Cura em Dungeons
-- Centros de cura em dungeons só podem ser usados uma única vez.
-- Cura por eventos de história continua permitida.

local DungeonMaps = {
  MT_MOON_1F = true, MT_MOON_2F = true, MT_MOON_B1F = true,
  ROCKET_HIDEOUT_1F = true, ROCKET_HIDEOUT_2F = true,
  ROCKET_HIDEOUT_3F = true, ROCKET_HIDEOUT_4F = true,
  POKEMON_TOWER_1F = true, POKEMON_TOWER_2F = true,
  POKEMON_TOWER_3F = true, POKEMON_TOWER_4F = true,
  POKEMON_TOWER_5F = true, POKEMON_TOWER_6F = true, POKEMON_TOWER_7F = true,
  SS_ANNE_1F = true, SS_ANNE_2F = true, SS_ANNE_B1F = true,
  SILPH_CO_1F = true, SILPH_CO_2F = true, SILPH_CO_3F = true,
  SILPH_CO_4F = true, SILPH_CO_5F = true, SILPH_CO_6F = true,
  SILPH_CO_7F = true, SILPH_CO_8F = true, SILPH_CO_9F = true,
  SILPH_CO_10F = true, SILPH_CO_11F = true,
  VICTORY_ROAD_1F = true, VICTORY_ROAD_2F = true, VICTORY_ROAD_3F = true,
  SEAFOAM_ISLANDS_1F = true, SEAFOAM_ISLANDS_2F = true,
  SEAFOAM_ISLANDS_B1F = true, SEAFOAM_ISLANDS_B2F = true,
  CERULEAN_CAVE_1F = true, CERULEAN_CAVE_2F = true, CERULEAN_CAVE_B1F = true,
  POWER_PLANT = true,
}

local CenterLimit = {}
local currentMap = nil

function CenterLimit.init(mod, state)
  CenterLimit.mod = mod
  CenterLimit.state = state
end

function CenterLimit.enable(mod, state)
  local m = CenterLimit.mod

  -- Rastrear mapa atual
  m.events:on("map.entered", function(ev)
    if ev.mapId then currentMap = ev.mapId end
  end)

  -- Bloquear cura em dungeon se já usou
  m.hooks:wrap("pokemon.healed", function(next_fn, game, mon)
    if currentMap and DungeonMaps[currentMap] then
      local uses = state:getCenterUses(currentMap)
      if uses > 0 then
        m.log:warn("[Nuzlocke] Centro em %s já usado — cura bloqueada", currentMap)
        return false
      end
      state:trackCenterUse(currentMap)
      m.log:info("[Nuzlocke] Centro em %s usado (1/%d)", currentMap, 1)
    end
    return next_fn(game, mon)
  end)

  m.log:info("[Nuzlocke] Limite de Centros em Dungeons ativado")
end

return CenterLimit
