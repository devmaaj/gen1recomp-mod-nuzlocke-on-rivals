-- rules.lua: Registro e lifecycle de todas as regras Nuzlocke
local Rules = {}

Rules.registry = {}

function Rules.register(name, ruleModule)
  Rules.registry[name] = ruleModule
end

function Rules.init(mod, state)
  for name, ruleModule in pairs(Rules.registry) do
    if ruleModule.init then
      ruleModule.init(mod, state)
    end
  end
end

function Rules.enable(mod, state)
  for name, ruleModule in pairs(Rules.registry) do
    if state:isRuleEnabled(name) then
      if ruleModule.enable then
        ruleModule.enable(mod, state)
      end
    else
      mod.log:info("[Nuzlocke] Regra desabilitada: %s", name)
    end
  end
end

return Rules
