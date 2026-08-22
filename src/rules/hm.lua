-- hm.lua: HM Exclusivo
-- "Cada HM só pode ser ensinada a um Pokémon por vez."
-- Pokémon mortos NÃO contam (moves foram limpos pelo death.lua).
-- Ao morrer, HM é liberada automaticamente.

local HM_MOVES = {
  "CUT", "FLY", "SURF", "STRENGTH", "FLASH",
}

local HM = {}

function HM.init(mod, state)
  HM.mod = mod
  HM.state = state
end

function HM.enable(mod, state)
  local m = HM.mod

  -- Hook: antes de ensinar um movimento, verificar HM exclusiva
  m.hooks:wrap("pokemon.move_learned", function(next_fn, mon, moveId)
    if not moveId then return next_fn(mon, moveId) end

    -- Verificar se é HM
    local isHM = false
    for _, hmMove in ipairs(HM_MOVES) do
      if moveId == hmMove then
        isHM = true
        break
      end
    end

    if not isHM then
      return next_fn(mon, moveId)
    end

    -- Verificar se outro Pokémon vivo já tem esta HM
    local game = m.mod and m.mod.game
    if not game or not game.save or not game.save.party then
      return next_fn(mon, moveId)
    end

    for _, partyMon in ipairs(game.save.party) do
      -- Pular o próprio mon e mons mortos
      if partyMon ~= mon and partyMon.hp and partyMon.hp > 0 then
        if partyMon.moves then
          for _, mv in ipairs(partyMon.moves) do
            if mv.id == moveId then
              m.log:warn("[Nuzlocke] HM %s já ensinada a %s — bloqueada",
                         moveId, partyMon.nickname or partyMon.species)
              return false  -- bloquear ensino
            end
          end
        end
      end
    end

    return next_fn(mon, moveId)
  end)

  m.log:info("[Nuzlocke] HM Exclusivo ativado")
end

return HM
