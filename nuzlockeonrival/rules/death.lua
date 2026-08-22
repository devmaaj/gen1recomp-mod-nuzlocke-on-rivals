-- death.lua: Morte Permanente
-- Pokémon desmaiado = morto (fantasma). Penalidade: zerar tudo.
-- Aplica ao SAIR da batalha, não durante (revive permitido em batalha).
-- Sprite vira ghost.png quando morto. Se todos mortos → game over com tela.

local GHOST_SPRITE = "assets/generated/battle/front/ghost.png"

local Death = {}

function Death.init(mod, state)
  Death.mod = mod
  Death.state = state
end

function Death.enable(mod, state)
  local m = Death.mod

  -- Sprite: mortos viram fantasma
  m.hooks:wrap("pokemon.sprite", function(next_fn, path, ctx)
    if ctx.mon and ctx.mon.hp and ctx.mon.hp <= 0 then
      return GHOST_SPRITE
    end
    return next_fn(path, ctx)
  end)

  -- Ícone: mortos viram fantasma
  m.hooks:wrap("pokemon.icon", function(next_fn, path, ctx)
    if ctx.mon and ctx.mon.hp and ctx.mon.hp <= 0 then
      return GHOST_SPRITE
    end
    return next_fn(path, ctx)
  end)

  -- Quando batalha termina, verificar party
  m.events:on("battle.ended", function(ev)
    local battle = ev.battle
    if not battle then return end

    -- Não aplicar em batalhas link
    if battle.kind == "link" then return end

    local game = battle.game
    if not game or not game.save or not game.save.party then return end

    local party = game.save.party
    local allDead = true

    for i, mon in ipairs(party) do
      if mon.hp and mon.hp > 0 then
        allDead = false
      else
        -- Registrar top dead antes de zerar
        state:addTopDead(mon.species, mon.nickname, mon.level, mon.sprite)

        -- Aplicar penalidade: zerar mon
        m.log:info("[Nuzlocke] %s morreu — penalidade aplicada", mon.nickname or mon.species)

        mon.level = 1
        mon.dvs = { hp = 0, attack = 0, defense = 0, speed = 0, special = 0 }
        mon.statExp = { hp = 0, attack = 0, defense = 0, speed = 0, special = 0 }
        mon.moves = {}
        mon.status = nil
        mon.exp = 0

        -- Recalcular stats
        local ok, Stats = pcall(require, "src.pokemon.Stats")
        if ok then
          local Data = require("src.core.Data")
          local speciesDef = Data.pokemon[mon.species]
          if speciesDef then
            mon.stats = Stats.calc(speciesDef, mon.level, mon.dvs, mon.statExp)
            mon.hp = 1
          end
        end

        -- Registrar morte
        state:addFainted(mon.species, mon.nickname)
      end
    end

    -- Se todos mortos → game over com tela
    if allDead and #party > 0 then
      m.log:info("[Nuzlocke] TODOS os Pokémon morreram — GAME OVER")
      state:set("game_over", true)

      -- Push tela de game over
      local function showGameOver()
        local TextBox = require("src.render.TextBox")
        local Font = require("src.render.Font")

        -- Tela customizada de game over
        local screen = {
          isOpaque = true,
          timer = 0,
          phase = "show",  -- show -> wait -> delete -> title
        }

        function screen:update(dt)
          screen.timer = screen.timer + dt
          if screen.phase == "show" and screen.timer > 3 then
            screen.phase = "wait"
          end
        end

        function screen:draw()
          local w, h = 160, 144

          -- Fundo preto
          love.graphics.setColor(0, 0, 0)
          love.graphics.rectangle("fill", 0, 0, w, h)

          -- Título GAME OVER
          love.graphics.setColor(1, 1, 1)
          Font.draw("GAME OVER", 48, 8)

          -- Estatísticas
          local deaths = state:getDeathsCount()
          local duels = state:getDuelsWon()
          local badges = state:getBadgesCount()

          Font.draw("Deaths: " .. deaths, 10, 32)
          Font.draw("Duels: " .. duels, 10, 44)
          Font.draw("Badges: " .. badges, 10, 56)

          -- Rival
          local rivalName = state:getRivalName()
          if rivalName then
            Font.draw("Rival: " .. rivalName, 10, 68)
          end

          -- Top 3 mortos
          local topDead = state:getTopDead()
          if #topDead > 0 then
            local startX = 30
            for i = 1, math.min(3, #topDead) do
              local mon = topDead[i]
              local x = startX + (i - 1) * 36

              -- Desenhar sprite original (não ghost)
              if mon.sprite then
                local ok, img = pcall(love.graphics.newImage, mon.sprite)
                if ok and img then
                  love.graphics.setColor(1, 1, 1)
                  love.graphics.draw(img, x, 72, 0, 2, 2)
                end
              end

              -- R.I.P.
              love.graphics.setColor(1, 1, 1)
              Font.draw("R.I.P.", x + 4, 100)
            end
          end

          -- Aguardando...
          if screen.phase == "wait" then
            Font.draw("...", 72, 120)
          end
        end

        function screen:keypressed(key)
          if screen.phase == "show" then
            screen.phase = "wait"
          end
        end

        -- Push a tela
        game.stack:push(screen)

        -- Após 5 segundos, deletar save e voltar ao título
        local Timer
        ok, Timer = pcall(require, "src.core.Timing")
        if ok and Timer.after then
          Timer.after(5, function()
            -- Deletar save
            local SaveData = require("src.core.SaveData")
            local GameVersion = require("src.core.GameVersion")
            local version = GameVersion.get()
            local slotId = SaveData.activeSlot(version)
            if slotId then
              SaveData.deleteSlot(version, slotId)
              m.log:info("[Nuzlocke] Save deletado: %s", slotId)
            end
            -- Voltar ao título
            game:returnToTitle()
          end)
        end
      end

      -- Chamar showGameOver no próximo frame
      local Timer
      ok, Timer = pcall(require, "src.core.Timing")
      if ok and Timer.after then
        Timer.after(0.1, showGameOver)
      else
        showGameOver()
      end
    end
  end)

  m.log:info("[Nuzlocke] Morte Permanente ativada (ghost sprite)")
end

return Death
