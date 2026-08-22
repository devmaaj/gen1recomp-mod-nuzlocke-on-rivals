-- main.lua: Entry point do Nuzlocke On Rival
local State = require("src/state")
local Rules = require("src/rules")

-- Registrar todas as regras
Rules.register("capture_limit",       require("src/rules/capture"))
Rules.register("nickname_required",   require("src/rules/nickname"))
Rules.register("death_permanent",     require("src/rules/death"))
Rules.register("game_over",           require("src/rules/game_over"))
Rules.register("hm_exclusive",        require("src/rules/hm"))
Rules.register("no_rematch",          require("src/rules/rematch"))
Rules.register("heal_items_battle_only", require("src/rules/items"))
Rules.register("no_shops",            require("src/rules/shops"))
Rules.register("accidental_death",    require("src/rules/accidental_death"))
Rules.register("academy_lock",        require("src/rules/academy"))
Rules.register("dungeon_once",        require("src/rules/dungeon"))
Rules.register("center_limit",        require("src/rules/center_limit"))

-- Registrar regras de link play
Rules.register("link_validation",     require("src/rules/link_validation"))
Rules.register("rival",               require("src/link/rival"))
Rules.register("dominance",           require("src/link/dominance"))
Rules.register("pink_slip",           require("src/link/pink_slip"))
Rules.register("negotiation",         require("src/link/negotiation"))

return function(mod)
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

  -- Título: render.hud desenha em window space (após Renderer:endFrame)
  -- Precisamos transformar coordenadas 160x144 → window usando viewport
  mod.hooks:wrap("render.hud", function(next_fn, game, viewport)
    local Font = require("src.render.Font")
    local top = game.stack and game.stack:top()
    local isTitle = top and top.onNewGame and top.logo
    if isTitle and viewport then
      -- viewport: { gameX, gameY, gameWidth, gameHeight, scale }
      local gx = viewport.gameX or 0
      local gy = viewport.gameY or 0
      local gw = viewport.gameWidth or 160
      local gh = viewport.gameHeight or 144
      local sx = gw / 160
      local sy = gh / 144
      love.graphics.push()
      love.graphics.translate(gx, gy)
      love.graphics.scale(sx, sy)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("NUZLOCKE ON RIVALS", 12, 136)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.pop()
    end
    return next_fn(game, viewport)
  end)

  mod.log:info("Nuzlocke On Rival v0.1.0 carregado")
end
