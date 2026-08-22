-- items.lua: Itens de Cura Limitados
-- Itens de cura só podem ser usados durante batalhas normais.
-- Em link battles: NENHUM item é permitido.
-- Fora de batalha: BLOQUEADO.
-- Poké Flute: excluído (objeto key).

local HEAL_ITEMS = {
  "POTION", "SUPER_POTION", "HYPER_POTION", "MAX_POTION", "FULL_RESTORE",
  "REVIVE", "MAX_REVIVE",
  "ETHER", "ELIXIR", "MAX_ETHER", "MAX_ELIXIR",
  "FULL_HEAL", "ANTIDOTE", "PARALYZ_HEAL", "AWAKENING",
  "BURN_HEAL", "ICE_HEAL",
}

local Items = {}

function Items.init(mod, state)
  Items.mod = mod
  Items.state = state
end

function Items.enable(mod, state)
  local m = Items.mod

  -- Hook: interceptar uso de item
  m.hooks:wrap("item.use", function(next_fn, game, item, target)
    if not item or not item.id then
      return next_fn(game, item, target)
    end

    -- Verificar se é item de cura
    local isHealItem = false
    for _, healItem in ipairs(HEAL_ITEMS) do
      if item.id == healItem then
        isHealItem = true
        break
      end
    end

    -- Itens que não são de cura, passar direto
    if not isHealItem then
      return next_fn(game, item, target)
    end

    -- Verificar se está em batalha
    local inBattle = game.stack and game.stack:top()
                     and game.stack:top().kind == "battle"

    -- Verificar se é link battle
    local isLink = inBattle and game.stack:top().kind == "link"

    -- Link battle: NENHUM item permitido
    if isLink then
      m.log:warn("[Nuzlocke] Item bloqueado em batalha link: %s", item.id)
      return false
    end

    -- Fora de batalha: bloqueado
    if not inBattle then
      m.log:warn("[Nuzlocke] Item bloqueado fora de batalha: %s", item.id)
      return false
    end

    -- Batalha normal: permitido
    return next_fn(game, item, target)
  end)

  m.log:info("[Nuzlocke] Itens de Cura Limitados ativados")
end

return Items
