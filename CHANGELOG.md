# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-21

### Added
- Scaffold do mod com estrutura base
- Módulo de estado central (state.lua)
- Sistema de registro de regras (rules.lua)
- Captura Limitada: primeiro encontro por rota bloqueia outros
- Apelido Obrigatório: NamingScreen forçado
- Morte Permanente: penalidade ao sair da batalha
- Ghost Sprite: Pokémon mortos viram fantasma
- Fim de Jogo: tela com stats, top 3 mortos, rival name, deletar save
- HM Exclusivo: 1 HM por Pokémon vivo
- Proibição de Rematch: bloqueia rematch com treinadores
- Itens de Cura Limitados: só em batalha normal
- Duelo de Dominância: MD3 melhor de 3 via link play
- Academias Sem Saída: trava saída até limpar gym
- Liga Pokémon: cura antes e depois de cada luta
- Dungeons de Uma Só Vez: trava saída até conclusão
- Limite de Centros em Dungeons: 1 uso por dungeon
- Sem Lojas: compras restritas a não-cura
- Negociações Permitidas: trade nativo
- Tela de título: "NUZLOCKE ON RIVALS" como subtítulo
- Validação de Link: NEW GAME/CONTINUE exigem link
- Meu Rival: rival NPC renomeado via link play

### Known Issues
- Tela de reordenação de party entre rounds MD3 (TODO)
- Testes unitários pendentes
