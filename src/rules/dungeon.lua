-- dungeon.lua: Dungeons de Uma Só Vez
-- Ao entrar, NÃO pode sair até chegar ao final.
-- Florestas NÃO são dungeons.
-- Revisita forçada pela história: permitir.

local DUNGEONS = {
  -- Cavernas
  "MT_MOON_1F", "MT_MOON_2F", "MT_MOON_B1F",
  "VICTORY_ROAD_1F", "VICTORY_ROAD_2F", "VICTORY_ROAD_3F",
  "SEAFOAM_ISLANDS_1F", "SEAFOAM_ISLANDS_2F",
  "SEAFOAM_ISLANDS_B1F", "SEAFOAM_ISLANDS_B2F",
  "CERULEAN_CAVE_1F", "CERULEAN_CAVE_2F", "CERULEAN_CAVE_B1F",
  -- Esconderijos
  "ROCKET_HIDEOUT_1F", "ROCKET_HIDEOUT_2F",
  "ROCKET_HIDEOUT_3F", "ROCKET_HIDEOUT_4F",
  -- Prédios com treinadores
  "SS_ANNE_1F", "SS_ANNE_2F", "SS_ANNE_B1F",
  "SILPH_CO_1F", "SILPH_CO_2F", "SILPH_CO_3F",
  "SILPH_CO_4F", "SILPH_CO_5F", "SILPH_CO_6F", "SILPH_CO_7F",
  "SILPH_CO_8F", "SILPH_CO_9F", "SILPH_CO_10F", "SILPH_CO_11F",
  "POKEMON_TOWER_1F", "POKEMON_TOWER_2F", "POKEMON_TOWER_3F",
  "POKEMON_TOWER_4F", "POKEMON_TOWER_5F", "POKEMON_TOWER_6F",
  "POKEMON_TOWER_7F",
}

-- Dungeons que história exige revisita
local REVISITABLE = {}

local Dungeon = {}
local inDungeon = nil

function Dungeon.init(mod, state)
  Dungeon.mod = mod
  Dungeon.state = state
end

function Dungeon.enable(mod, state)
  local m = Dungeon.mod

  -- Detectar entrada em dungeon
  m.events:on("map.entered", function(ev)
    local mapId = ev.mapId
    if not mapId then return end

    -- Verificar se é dungeon
    for _, dungeonId in ipairs(DUNGEONS) do
      if mapId == dungeonId then
        -- Verificar se já visitou
        local visits = state:getDungeonVisits(dungeonId)
        local canRevisit = false
        for _, revId in ipairs(REVISITABLE) do
          if dungeonId == revId then
            canRevisit = true
            break
          end
        end

        if visits > 0 and not canRevisit then
          m.log:warn("[Nuzlocke] Re-entrada bloqueada: %s", dungeonId)
          -- TODO: push mensagem e voltar (Fase 20)
        else
          inDungeon = dungeonId
          state:trackDungeonVisit(dungeonId)
          m.log:info("[Nuzlocke] Entrou em dungeon: %s", dungeonId)
        end
        break
      end
    end
  end)

  -- Bloquear saída de dungeon
  m.hooks:wrap("warp.destination", function(next_fn, destMap, x, y, opts)
    if inDungeon then
      -- Verificar se destino é outro mapa da mesma dungeon
      local isSameDungeon = false
      for _, dungeonId in ipairs(DUNGEONS) do
        if destMap == dungeonId then
          isSameDungeon = true
          break
        end
      end

      -- Se saindo da dungeon (indo para mapa que NÃO é dungeon)
      if not isSameDungeon then
        m.log:warn("[Nuzlocke] Saída bloqueada — dungeon %s não concluída", inDungeon)
        return inDungeon, x, y  -- manter no mesmo mapa
      end
    end
    return next_fn(destMap, x, y, opts)
  end)

  m.log:info("[Nuzlocke] Dungeons de Uma Só Vez ativadas")
end

return Dungeon
