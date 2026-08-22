-- rival.lua: Meu Rival (Link Play)
-- "Cada jogador deve nomear seu Rival com o mesmo nome do oponente."
-- Hook: intro.oak_speech.answered → sobrescrever nome do rival com nome do link

local Rival = {}

function Rival.init(mod, state)
  Rival.mod = mod
  Rival.state = state
end

function Rival.enable(mod, state)
  local m = Rival.mod

  -- Hook: interceptar Oak Speech quando rival é nomeado
  m.hooks:wrap("intro.oak_speech.answered", function(next_fn, ev)
    -- Se o step é "name_rival" e temos link, usar nome do oponente
    if ev.step and ev.step.id == "name_rival" then
      local firstLink = state:getFirstLinkName()
      if firstLink then
        m.log:info("[Nuzlocke] Rival renomeado: %s → %s (link)", ev.value, firstLink)
        -- Sobrescrever o valor salvo no save
        local game = ev.speech and ev.speech.game
        if game and game.save and game.save.player then
          game.save.player.rival = firstLink
        end
        -- Retornar o novo valor para o Oak Speech
        return next_fn(ev)
      end
    end
    return next_fn(ev)
  end)

  -- Event: quandoOak speech termina, garantir que rival está correto
  m.events:on("intro.oak_speech.finished", function(ev)
    local firstLink = state:getFirstLinkName()
    if firstLink and ev.answers then
      local game = ev.speech and ev.speech.game
      if game and game.save and game.save.player then
        game.save.player.rival = firstLink
        m.log:info("[Nuzlocke] Rival final: %s", firstLink)
      end
    end
  end)

  m.log:info("[Nuzlocke] Meu Rival ativado")
end

return Rival
