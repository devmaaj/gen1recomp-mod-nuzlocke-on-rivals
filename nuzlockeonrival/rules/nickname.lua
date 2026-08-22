-- nickname.lua: Apelido Obrigatório
-- "Todos os Pokémon capturados devem receber apelidos para criar vínculo."
-- Após pokemon.caught, se mon não tem apelido, forçar NamingScreen.

local Nickname = {}

function Nickname.init(mod, state)
  Nickname.mod = mod
  Nickname.state = state
end

function Nickname.enable(mod, state)
  local m = Nickname.mod

  -- Event: quando Pokémon é capturado, verificar apelido
  m.events:on("pokemon.caught", function(ev)
    local mon = ev.mon
    if not mon then return end

    -- Se já tem apelido (de evento ou trade), nada a fazer
    if mon.nickname and #mon.nickname > 0 then return end

    local game = ev.game
    if not game then return end

    m.log:info("[Nuzlocke] Forçando apelido para %s", ev.species)

    -- Push NamingScreen direto (sem delay, sem depender do prompt do engine)
    local ok, Screens = pcall(require, "src.core.Screens")
    if not ok then return end

    pcall(Screens.push, game, "NamingScreen", {
      title = "NICKNAME?",
      maxLen = 10,
      onDone = function(name)
        if name and #name > 0 then
          mon.nickname = name
          m.log:info("[Nuzlocke] Apelido: %s → %s", ev.species, name)
        else
          -- Se apertar B sem digitar, forçar nome padrão
          mon.nickname = mon.species
          m.log:info("[Nuzlocke] Apelido padrão: %s → %s", ev.species, mon.species)
        end
      end,
    })
  end)

  m.log:info("[Nuzlocke] Apelido Obrigatório ativado")
end

return Nickname
