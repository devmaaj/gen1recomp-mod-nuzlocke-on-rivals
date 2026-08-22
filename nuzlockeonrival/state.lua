-- state.lua: Gerenciamento central de estado do Nuzlocke On Rival
local State = {}
State.__index = State

function State.new(mod)
  local self = setmetatable({}, State)
  self.mod = mod
  return self
end

-- Privado: obter tabela raiz do Nuzlocke
local function root(self)
  local data = self.mod.save:get("nuzlocke", {})
  if not data._initialized then
    data = {
      _initialized = true,
      encountered_areas = {},
      captured_areas = {},
      fainted_mons = {},
      defeated_trainers = {},
      dungeon_visits = {},
      center_uses = {},
      accidental_deaths = {},
      current_academy = nil,
      academy_trainers = {},
      rival_name = nil,
      first_link_name = nil,
      -- Estatísticas de game over
      deaths_count = 0,
      duels_won = 0,
      badges_count = 0,
      top_dead = {},  -- top 3 mortos mais fortes
      rules_enabled = {
        capture_limit = true,
        nickname_required = true,
        death_permanent = true,
        game_over = true,
        hm_exclusive = true,
        no_rematch = true,
        heal_items_battle_only = true,
        no_shops = true,
        accidental_death = true,
        academy_lock = true,
        dungeon_once = true,
        shiny_clause = true,
        center_limit = true,
      },
    }
    self.mod.save:set("nuzlocke", data)
  end
  return data
end

-- Privado: salvar estado
local function save(self, data)
  self.mod.save:set("nuzlocke", data)
end

-- Captura: rastrear áreas
function State:hasEncounteredInArea(areaId)
  return root(self).encountered_areas[areaId] == true
end

function State:trackEncounter(areaId)
  local data = root(self)
  data.encountered_areas[areaId] = true
  save(self, data)
end

function State:hasCapturedInArea(areaId)
  return root(self).captured_areas[areaId] == true
end

function State:trackCapture(areaId)
  local data = root(self)
  data.captured_areas[areaId] = true
  save(self, data)
end

-- Morte: rastrear Pokémon mortos
function State:addFainted(species, nickname)
  local data = root(self)
  table.insert(data.fainted_mons, {
    species = species,
    nickname = nickname or species,
    timestamp = os.time(),
  })
  data.deaths_count = (data.deaths_count or 0) + 1
  save(self, data)
end

function State:getFainted()
  return root(self).fainted_mons
end

function State:getDeathsCount()
  return root(self).deaths_count or 0
end

-- Top dead: registrar mon morto com level para ranking
function State:addTopDead(species, nickname, level, sprite)
  local data = root(self)
  table.insert(data.top_dead, {
    species = species,
    nickname = nickname or species,
    level = level or 1,
    sprite = sprite,
  })
  -- Manter só top 3 (maior level)
  table.sort(data.top_dead, function(a, b) return a.level > b.level end)
  while #data.top_dead > 3 do
    table.remove(data.top_dead)
  end
  save(self, data)
end

function State:getTopDead()
  return root(self).top_dead or {}
end

-- Duelos vencidos
function State:addDuelWin()
  local data = root(self)
  data.duels_won = (data.duels_won or 0) + 1
  save(self, data)
end

function State:getDuelsWon()
  return root(self).duels_won or 0
end

-- Insígnias
function State:setBadgesCount(count)
  local data = root(self)
  data.badges_count = count
  save(self, data)
end

function State:getBadgesCount()
  return root(self).badges_count or 0
end

-- Treinadores derrotados
function State:markTrainerDefeated(trainerId)
  local data = root(self)
  data.defeated_trainers[trainerId] = true
  save(self, data)
end

function State:isTrainerDefeated(trainerId)
  return root(self).defeated_trainers[trainerId] == true
end

-- Dungeons
function State:trackDungeonVisit(dungeonId)
  local data = root(self)
  data.dungeon_visits[dungeonId] = (data.dungeon_visits[dungeonId] or 0) + 1
  save(self, data)
end

function State:getDungeonVisits(dungeonId)
  return root(self).dungeon_visits[dungeonId] or 0
end

-- Centros de cura em dungeons
function State:trackCenterUse(dungeonId)
  local data = root(self)
  data.center_uses[dungeonId] = (data.center_uses[dungeonId] or 0) + 1
  save(self, data)
end

function State:getCenterUses(dungeonId)
  return root(self).center_uses[dungeonId] or 0
end

-- Morte acidental
function State:setAccidentalDeath(areaId)
  local data = root(self)
  data.accidental_deaths[areaId] = true
  save(self, data)
end

function State:hasAccidentalDeath(areaId)
  return root(self).accidental_deaths[areaId] == true
end

-- Academias
function State:setAcademyEntry(academyId)
  local data = root(self)
  data.current_academy = academyId
  save(self, data)
end

function State:clearAcademyEntry()
  local data = root(self)
  data.current_academy = nil
  save(self, data)
end

function State:getCurrentAcademy()
  return root(self).current_academy
end

function State:markAcademyTrainerDefeated(academyId, trainerId)
  local data = root(self)
  if not data.academy_trainers[academyId] then
    data.academy_trainers[academyId] = {}
  end
  data.academy_trainers[academyId][trainerId] = true
  save(self, data)
end

function State:getAcademyTrainerCount(academyId)
  local trainers = root(self).academy_trainers[academyId] or {}
  local count = 0
  for _ in pairs(trainers) do count = count + 1 end
  return count
end

-- Rival (link play)
function State:setRivalName(name)
  local data = root(self)
  data.rival_name = name
  save(self, data)
end

function State:getRivalName()
  return root(self).rival_name
end

-- Primeiro link
function State:setFirstLinkName(name)
  local data = root(self)
  data.first_link_name = name
  save(self, data)
end

function State:getFirstLinkName()
  return root(self).first_link_name
end

function State:hasFirstLink()
  return root(self).first_link_name ~= nil
end

-- Configurações
function State:isRuleEnabled(ruleName)
  return root(self).rules_enabled[ruleName] == true
end

function State:setRuleEnabled(ruleName, enabled)
  local data = root(self)
  data.rules_enabled[ruleName] = enabled
  save(self, data)
end

return State
