-- shops.lua: Sem Lojas (compras restritas)
-- Jogadores NÃO podem comprar itens de cura/recuperação.
-- Podem comprar: Pokébolas, Repelentes, Pedras de Evolução, TMs.
-- Itens de cura: Potion, Revive, Ether, status cures, etc.

local BLOCKED_ITEMS = {
  "POTION", "SUPER_POTION", "HYPER_POTION", "MAX_POTION", "FULL_RESTORE",
  "REVIVE", "MAX_REVIVE",
  "ETHER", "ELIXIR", "MAX_ETHER", "MAX_ELIXIR",
  "FULL_HEAL", "ANTIDOTE", "PARALYZ_HEAL", "AWAKENING",
  "BURN_HEAL", "ICE_HEAL",
  "LAVA_COOKIE",
}

local Shops = {}

function Shops.init(mod, state)
  Shops.mod = mod
  Shops.state = state
end

function Shops.enable(mod, state)
  local m = Shops.mod

  -- Hook: bloquear compra de itens de cura
  m.hooks:wrap("shop.buy", function(next_fn, game, item, quantity)
    if not item or not item.id then
      return next_fn(game, item, quantity)
    end

    -- Verificar se é item bloqueado
    for _, blocked in ipairs(BLOCKED_ITEMS) do
      if item.id == blocked then
        m.log:warn("[Nuzlocke] Compra bloqueada: %s (item de cura)", item.id)
        return false
      end
    end

    -- Itens permitidos: Pokébolas, Repel, TMs, Pedras, etc.
    return next_fn(game, item, quantity)
  end)

  m.log:info("[Nuzlocke] Sem Lojas (compras restritas) ativado")
end

return Shops
