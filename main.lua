-- main.lua: Entry point do Nuzlocke On Rival

return function(mod)
  -- Adicionar pasta do mod ao package.path para require funcionar
  local modDir = mod.path:gsub("\\", "/")
  package.path = modDir .. "/?.lua;" .. package.path

  local State = require("nuzlockeonrival/state")
  local Rules = require("nuzlockeonrival/rules")

  -- Registrar todas as regras
  Rules.register("capture_limit",       require("nuzlockeonrival/rules/capture"))
  Rules.register("nickname_required",   require("nuzlockeonrival/rules/nickname"))
  Rules.register("death_permanent",     require("nuzlockeonrival/rules/death"))
  Rules.register("game_over",           require("nuzlockeonrival/rules/game_over"))
  Rules.register("hm_exclusive",        require("nuzlockeonrival/rules/hm"))
  Rules.register("no_rematch",          require("nuzlockeonrival/rules/rematch"))
  Rules.register("heal_items_battle_only", require("nuzlockeonrival/rules/items"))
  Rules.register("no_shops",            require("nuzlockeonrival/rules/shops"))
  Rules.register("accidental_death",    require("nuzlockeonrival/rules/accidental_death"))
  Rules.register("academy_lock",        require("nuzlockeonrival/rules/academy"))
  Rules.register("dungeon_once",        require("nuzlockeonrival/rules/dungeon"))
  Rules.register("center_limit",        require("nuzlockeonrival/rules/center_limit"))

  -- Registrar regras de link play
  Rules.register("link_validation",     require("nuzlockeonrival/rules/link_validation"))
  Rules.register("rival",               require("nuzlockeonrival/link/rival"))
  Rules.register("dominance",           require("nuzlockeonrival/link/dominance"))
  Rules.register("pink_slip",           require("nuzlockeonrival/link/pink_slip"))
  Rules.register("negotiation",         require("nuzlockeonrival/link/negotiation"))

  local state = State.new(mod)

  -- Inicializar todas as regras
  Rules.init(mod, state)

  -- Ativar apenas regras habilitadas
  Rules.enable(mod, state)

  -- UI: adicionar tela de status ao menu inicial
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "NUZLOCKE STATUS",
      onSelect = function()
        mod.log:info("[Nuzlocke] Abrindo status...")
      end,
    })
  end)

  mod.log:info("Nuzlocke On Rival v0.1.0 carregado")
end
