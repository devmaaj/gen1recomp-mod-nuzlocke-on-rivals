-- capture.lua: Captura Limitada
-- "Apenas o primeiro Pokémon encontrado em cada área pode ser capturado."
-- Após o primeiro encontro selvagem em uma rota, todos os outros são bloqueados.
-- Área = rota inteira (ex: ROUTE_1, VIRIDIAN_FOREST)
-- Treinadores e Pokémon de evento NÃO contam.

local Capture = {}
local currentArea = nil

function Capture.init(mod, state)
  Capture.mod = mod
  Capture.state = state
end

function Capture.enable(mod, state)
  local m = Capture.mod

  -- Rastrear mapa atual a cada passo
  m.events:on("world.stepped", function(ev)
    if ev.mapId then currentArea = ev.mapId end
  end)

  -- Marcar encontro quando batalha selvagem inicia
  -- battle.started fires with { battle, ... }
  -- battle.kind == "wild" para encontros selvagens
  m.events:on("battle.started", function(ev)
    local battle = ev.battle
    if battle and battle.kind == "wild" then
      local areaId = currentArea
      if areaId then
        state:trackEncounter(areaId)
        m.log:info("[Nuzlocke] Encontro registrado em %s", areaId)
      end
    end
  end)

  -- Bloquear encontro se já encontrou na área
  -- encounter.roll receives (encDef, ctx) where ctx = { mapId, terrain, rng }
  m.hooks:wrap("encounter.roll", function(next_fn, encDef, ctx)
    local areaId = ctx and ctx.mapId or currentArea
    if areaId and state:hasEncounteredInArea(areaId) then
      return nil  -- suprimir encontro
    end
    return next_fn(encDef, ctx)
  end)

  m.log:info("[Nuzlocke] Captura Limitada ativada")
end

return Capture
