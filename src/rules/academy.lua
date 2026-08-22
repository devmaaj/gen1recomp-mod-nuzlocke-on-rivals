-- academy.lua: Academias Sem Saída + Liga Pokémon
-- Não pode sair de Gym/Dojo até derrotar TODOS os treinadores.
-- Antes do líder: cura party (sem revive).
-- Liga Pokémon: cura ANTES e DEPOIS de cada luta.

local GYM_MAPS = {
  PEWTER_GYM = { beatFlag = "EVENT_BEAT_PEWTER_GYM" },
  CERULEAN_GYM = { beatFlag = "EVENT_BEAT_CERULEAN_GYM" },
  VERMILION_GYM = { beatFlag = "EVENT_BEAT_VERMILION_GYM" },
  CELADON_GYM = { beatFlag = "EVENT_BEAT_CELADON_GYM" },
  FUCHSIA_GYM = { beatFlag = "EVENT_BEAT_FUCHSIA_GYM" },
  SAFFRON_GYM = { beatFlag = "EVENT_BEAT_SAFFRON_GYM" },
  CINNABAR_GYM = { beatFlag = "EVENT_BEAT_CINNABAR_GYM" },
  VIRIDIAN_GYM = { beatFlag = "EVENT_BEAT_VIRIDIAN_GYM" },
}

-- Liga Pokémon: Elite Four + Champion
local LEAGUE_MAPS = {
  LORELEIS_ROOM = true, BRUNOS_ROOM = true,
  AGATHAS_ROOM = true, LANCES_ROOM = true,
  CHAMPIONS_ROOM = true,
}

-- Cura party (NÃO revive mortos)
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
  m.log:info("[Nuzlocke] Party curada (sem revive): %d mons", healed)
end

local Academy = {}
local inGym = nil
local isLeague = false

function Academy.init(mod, state)
  Academy.mod = mod
  Academy.state = state
end

function Academy.enable(mod, state)
  local m = Academy.mod

  -- Detectar entrada em Gym/League
  m.events:on("map.entered", function(ev)
    local mapId = ev.mapId
    if not mapId then return end

    -- Gym?
    if GYM_MAPS[mapId] then
      local gym = GYM_MAPS[mapId]
      local flags = ev.game and ev.game.save and ev.game.save.flags or {}
      if not flags[gym.beatFlag] then
        inGym = mapId
        state:setAcademyEntry(mapId)
        m.log:info("[Nuzlocke] Entrou em Gym: %s", mapId)
      end
    end

    -- Liga Pokémon?
    if LEAGUE_MAPS[mapId] then
      isLeague = true
      m.log:info("[Nuzlocke] Entrou na Liga: %s", mapId)
      -- Cura antes de cada luta da liga
      local game = ev.game
      if game then
        healPartyNoRevive(game, m)
      end
    end
  end)

  -- Bloquear saída de Gym
  m.hooks:wrap("warp.destination", function(next_fn, destMap, x, y, opts)
    if inGym then
      -- Verificar se Gym foi limpo
      local flags = {}
      local game = opts and opts.game
      if game and game.save then
        flags = game.save.flags or {}
      end
      local gym = GYM_MAPS[inGym]
      if gym and not flags[gym.beatFlag] then
        m.log:warn("[Nuzlocke] Saída bloqueada — Gym %s não limpo", inGym)
        return inGym, x, y  -- manter no mesmo mapa
      end
    end
    return next_fn(destMap, x, y, opts)
  end)

  -- Curar antes do líder de Ginásio
  m.events:on("battle.started", function(ev)
    local battle = ev.battle
    if not battle then return end

    -- Se é treinador em Gym e é o líder (último)
    if inGym and battle.kind == "trainer" then
      local game = battle.game
      if game then
        m.log:info("[Nuzlocke] Gym battle — cura antes do líder")
        healPartyNoRevive(game, m)
      end
    end

    -- Liga Pokémon: cura antes de cada luta
    if isLeague and battle.kind == "trainer" then
      local game = battle.game
      if game then
        m.log:info("[Nuzlocke] Liga battle — cura antes")
        healPartyNoRevive(game, m)
      end
    end
  end)

  -- Quando Gym é limpo (líder derrotado)
  m.events:on("battle.ended", function(ev)
    local battle = ev.battle
    if not battle then return end

    -- Gym limpo
    if inGym and battle.kind == "trainer" and ev.result == "win" then
      local gym = GYM_MAPS[inGym]
      if gym then
        local game = battle.game
        if game and game.save then
          game.save.flags = game.save.flags or {}
          game.save.flags[gym.beatFlag] = true
          m.log:info("[Nuzlocke] Gym %s limpo!", inGym)
          inGym = nil
          state:clearAcademyEntry()
        end
      end
    end

    -- Liga: cura após cada luta
    if isLeague and battle.kind == "trainer" then
      local game = battle.game
      if game then
        m.log:info("[Nuzlocke] Liga battle — cura após")
        healPartyNoRevive(game, m)
      end
      -- Sair da liga se Champion derrotado
      if battle.trainerId and battle.trainerId:find("RIVAL3") then
        isLeague = false
        m.log:info("[Nuzlocke] Liga completa!")
      end
    end
  end)

  m.log:info("[Nuzlocke] Academias Sem Saída + Liga Pokémon ativados")
end

return Academy
