-- link_validation.lua: Validação de Link no Título
-- NEW GAME e CONTINUE só funcionam se estiver linkado.
-- Ao linkar: salva nome do oponente como rival.
-- Ao carregar save: verifica se link atual == rival salvo.

local LinkValidation = {}
local mod_ref = nil
local state_ref = nil

function LinkValidation.init(mod, state)
  mod_ref = mod
  state_ref = state
end

function LinkValidation.enable(mod, state)
  -- Event: quando conecta via link, salvar nome do oponente
  mod.events:on("link.connected", function(ev)
    local remoteName = ev.remote and ev.remote.name
    if remoteName then
      -- Primeiro link = rival definitivo
      if not state:hasFirstLink() then
        state:setFirstLinkName(remoteName)
        state:setRivalName(remoteName)
        mod.log:info("[Nuzlocke] Primeiro link: rival definido como '%s'", remoteName)
      else
        mod.log:info("[Nuzlocke] Link conectado: '%s'", remoteName)
      end
    end
  end)

  -- Hook: interceptar menu título
  mod.hooks:wrap("ui.title_menu.items", function(next_fn, game, items)
    local out = next_fn(game, items)
    if type(out) ~= "table" then return out end

    -- Envolver cada item para verificar link
    for _, item in ipairs(out) do
      if item.label and (item.label:find("NEW GAME") or item.label:find("CONTINUE")) then
        local originalOnSelect = item.onSelect
        item.onSelect = function()
          -- Verificar se está linkado
          local linked = game.linkSession or game.linkNet
          if not linked then
            mod.log:warn("[Nuzlocke] Não linkado — acesse LINK primeiro")
            -- TODO: mostrar tela de link (Fase 20)
            -- Por enquanto, apenas bloquear
            return
          end

          -- Se CONTINUE, verificar se link atual == rival salvo
          if item.label:find("CONTINUE") and state:hasFirstLink() then
            local remoteName = linked.peerName or linked.remoteName
            local savedRival = state:getFirstLinkName()
            if remoteName and remoteName ~= savedRival then
              mod.log:warn("[Nuzlocke] Link '%s' != rival '%s' — bloqueado",
                           remoteName, savedRival)
              -- TODO: mostrar mensagem de erro (Fase 20)
              return
            end
          end

          -- Tudo OK, prosseguir
          if originalOnSelect then
            originalOnSelect()
          end
        end
      end
    end

    return out
  end)

  mod.log:info("[Nuzlocke] Validação de Link ativada")
end

return LinkValidation
