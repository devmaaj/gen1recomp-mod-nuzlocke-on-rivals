-- rematch.lua: Proibição de Rematch
-- "Não é permitido refazer batalhas contra NPCs ou Rivais."
-- Blocks rematch with any trainer already defeated.

local Rematch = {}

function Rematch.init(mod, state)
  Rematch.mod = mod
  Rematch.state = state
end

function Rematch.enable(mod, state)
  local m = Rematch.mod

  -- Register trainer as defeated after battle
  m.events:on("battle.ended", function(ev)
    local battle = ev.battle
    if not battle then return end

    if battle.kind == "trainer" and ev.result == "win" then
      local trainerId = battle.trainerId
      if trainerId then
        state:markTrainerDefeated(trainerId)
        m.log:info("[Nuzlocke] Treinador derrotado: %s", trainerId)
      end
    end
  end)

  -- Hook: block rematch via script
  m.hooks:wrap("script.command", function(next_fn, ctx, name, args)
    if name == "start_battle" and args[1] == "trainer" then
      local trainerId = args[2]
      if trainerId and state:isTrainerDefeated(trainerId) then
        m.log:warn("[Nuzlocke] Rematch bloqueado: %s já derrotado", trainerId)
        return nil
      end
    end

    return next_fn(ctx, name, unpack(args))
  end)

  m.log:info("[Nuzlocke] Proibição de Rematch ativada")
end

return Rematch
