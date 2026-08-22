-- dominance.lua: Duelo de Dominância — MD3 (melhor de 3)
-- Batalha link no mesmo local da batalha NPC rival.
-- Após rival: cura total (revive mortos, cura status, recupera PP).
-- Antes do MD3: cura party (NÃO revive mortos).
-- MD3: entre rounds, tela de reordenação de party.
-- Pink Slip: só ao final do MD3.

local Dominance = {}
local waitingForLink = false
local pendingCtx = nil
local pendingBattleLocation = nil
local afterRivalBattle = false

-- Estado do MD3
local md3 = {
  active = false,
  wins = 0,
  losses = 0,
  round = 0,
  maxRounds = 3,
}

local function resetMd3()
  md3.active = false
  md3.wins = 0
  md3.losses = 0
  md3.round = 0
end

local function isMd3Over()
  return md3.wins >= 2 or md3.losses >= 2
end

local function getMd3Winner()
  if md3.wins >= 2 then return "player" end
  if md3.losses >= 2 then return "rival" end
  return nil
end

-- Cura total: revive mortos, cura HP, status, PP
local function fullHealParty(game, m)
  if not game or not game.save or not game.save.party then return end
  local Data = require("src.core.Data")
  local healed = 0

  for _, mon in ipairs(game.save.party) do
    if mon.hp <= 0 then
      local speciesDef = Data.pokemon[mon.species]
      if speciesDef then
        mon.stats = mon.stats or {}
        mon.stats.hp = mon.stats.hp or speciesDef.baseStats.hp
        mon.hp = mon.stats.hp
        mon.status = nil
        healed = healed + 1
      end
    end
    if mon.hp > 0 and mon.stats and mon.hp < mon.stats.hp then
      mon.hp = mon.stats.hp
    end
    mon.status = nil
    if mon.moves then
      local moves = Data.moves
      for _, mv in ipairs(mon.moves) do
        if moves and moves[mv.id] then
          mv.pp = moves[mv.id].pp + (mv.ppUps or 0) * math.floor(moves[mv.id].pp / 5)
        end
      end
    end
  end
  m.log:info("[Nuzlocke] Party curada (full): %d revividos", healed)
end

-- Cura party (NÃO revive mortos): cura HP, status, PP
local function healPartyNoRevive(game, m)
  if not game or not game.save or not game.save.party then return end
  local Data = require("src.core.Data")
  local healed = 0

  for _, mon in ipairs(game.save.party) do
    if mon.hp > 0 then
      if mon.stats and mon.hp < mon.stats.hp then
        mon.hp = mon.stats.hp
        healed = healed + 1
      end
      mon.status = nil
      if mon.moves then
        local moves = Data.moves
        for _, mv in ipairs(mon.moves) do
          if moves and moves[mv.id] then
            mv.pp = moves[mv.id].pp + (mv.ppUps or 0) * math.floor(moves[mv.id].pp / 5)
          end
        end
      end
    end
  end
  m.log:info("[Nuzlocke] Party curada (sem revive): %d curados", healed)
end

function Dominance.init(mod, state)
  Dominance.mod = mod
  Dominance.state = state
end

function Dominance.enable(mod, state)
  local m = Dominance.mod

  -- Hook: interceptar rival_battle no script
  m.hooks:wrap("script.command", function(next_fn, ctx, name, args)
    if name == "rival_battle" then
      local rivalName = state:getRivalName()
      if not rivalName then
        return next_fn(ctx, name, unpack(args))
      end

      m.log:info("[Nuzlocke] rival_battle interceptado — aguardando link")
      afterRivalBattle = true
      pendingCtx = ctx
      waitingForLink = true

      -- Salvar localização atual (mesmo local da batalha NPC)
      local game = ctx.game or (ctx.overworld and ctx.overworld.game)
      if game and game.overworld and game.overworld.map then
        pendingBattleLocation = {
          mapId = game.overworld.map.id,
          x = game.overworld.player and game.overworld.player.cellX,
          y = game.overworld.player and game.overworld.player.cellY,
        }
      end

      local TextBox = require("src.render.TextBox")
      if game then
        game.stack:push(TextBox.new(game,
          "DUELO DE DOMINANCIA\\nAguardando rival\\nhumano via LINK..."))
      end

      ctx.runner:yield()
      return nil
    end

    return next_fn(ctx, name, unpack(args))
  end)

  -- Link conectou
  m.events:on("link.connected", function(ev)
    if not waitingForLink then return end

    local remoteName = ev.remote and ev.remote.name
    m.log:info("[Nuzlocke] Link conectado: %s", remoteName)

    waitingForLink = false
    if pendingCtx then
      pendingCtx.lastBattleResult = "win"
      m.log:info("[Nuzlocke] Batalha contra rival — script continua")
      pendingCtx = nil
    end
  end)

  -- Batalha termina
  m.events:on("battle.ended", function(ev)
    local battle = ev.battle
    if not battle then return end

    -- Após batalha contra rival NPC: cura total
    if afterRivalBattle and battle.kind ~= "link" then
      afterRivalBattle = false
      m.log:info("[Nuzlocke] Rival derrotado — cura total antes do MD3")
      local game = battle.game
      if game then
        fullHealParty(game, m)
      end
      -- Iniciar MD3
      resetMd3()
      md3.active = true
      md3.round = 1
      m.log:info("[Nuzlocke] MD3 iniciado — Round 1 (cura sem revive)")
      return
    end

    -- Link battle: MD3 round
    if battle.kind == "link" and md3.active then
      md3.round = md3.round + 1

      if ev.result == "win" then
        md3.wins = md3.wins + 1
        m.log:info("[Nuzlocke] MD3 Round %d: VITÓRIA (%d-%d)",
                   md3.round - 1, md3.wins, md3.losses)
      elseif ev.result == "lose" then
        md3.losses = md3.losses + 1
        m.log:info("[Nuzlocke] MD3 Round %d: DERROTA (%d-%d)",
                   md3.round - 1, md3.wins, md3.losses)
      else
        m.log:info("[Nuzlocke] MD3 Round %d: EMPATE", md3.round - 1)
      end

      -- MD3 acabou?
      if isMd3Over() then
        local winner = getMd3Winner()
        m.log:info("[Nuzlocke] MD3 FINALIZADO — vencedor: %s", winner)

        if winner == "player" then
          local loserParty = battle.enemyParty
          if loserParty and #loserParty > 0 then
            local randomIndex = math.random(1, #loserParty)
            local stolenMon = loserParty[randomIndex]
            m.log:info("[Nuzlocke] Pink Slip: %s roubado", stolenMon.species)
            local game = battle.game
            if game and game.save and game.save.party then
              table.insert(game.save.party, stolenMon)
            end
          end
          state:addDuelWin()
        else
          m.log:info("[Nuzlocke] Pink Slip: rival levou seu Pokémon")
          local loserParty = battle.game and battle.game.save and battle.game.save.party
          if loserParty and #loserParty > 0 then
            local randomIndex = math.random(1, #loserParty)
            table.remove(loserParty, randomIndex)
          end
        end

        resetMd3()
      else
        -- Próximo round: cura sem revive + tela de reordenação
        m.log:info("[Nuzlocke] MD3 Round %d — cura sem revive + reordenar", md3.round - 1)
        local game = battle.game
        if game then
          healPartyNoRevive(game, m)
        end
        -- TODO: push tela de reordenação (Fase 20)
      end
    end
  end)

  m.log:info("[Nuzlocke] Duelo de Dominância MD3 ativado")
end

return Dominance
