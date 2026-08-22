# Nuzlocke On Rival

A competitive 1v1 Nuzlocke challenge between two players connected via link play. Every decision can determine victory or defeat. Test your knowledge, choices, and ability to overcome opponents under pressure.

## Rules

### Competition Rules

- **My Rival** – Each player must name their Rival (NPC) in-game with the same name used by the opponent.

- **Rival Duels** – All rival duels must occur simultaneously. Dynamic or optional encounters against rivals may only be triggered by mutual agreement between players. No player may force these encounters without consent.

- **Dominance Duel** – After each battle against the Rival (NPC), players face each other in a Best of 3 (MD3) using exactly the same Pokémon that participated and survived that battle. The first Dominance Duel (after receiving your starter) occurs at the first Pokémon Center both players find, and both players are subject to the **Rivalry Mark**. Subsequent duels occur at the nearest Pokémon Center, and the winner must apply the **Pink Slip** rule to the defeated player. Permanent death does NOT apply in Dominance Duels.

- **Pink Slip** – After a Dominance Duel, the winner chooses one Pokémon from the defeated player's team. The trade occurs at a Pokémon Center, where the winner may offer any Pokémon as currency, and the loser must send the chosen Pokémon.

- **Negotiations Allowed** – Players may negotiate at any time, and once an agreement is made, both parties must fulfill it without exception.

### Core Rules

- **Limited Capture** – Only the first Pokémon encountered in each area may be caught. After the first encounter in a route, all subsequent encounters are blocked.

- **Mandatory Nickname** – All caught Pokémon must receive nicknames to create a bond.

- **Permanent Death** – If a Pokémon faints, it is considered "dead" and must be moved to the **R.I.P. Box**. Dead Pokémon become ghost sprites, are zeroed out (level 1, no moves, minimum stats), and cannot be used again.

- **Game Over** – When all Pokémon in the party faint, the challenge ends and the player is declared the loser. The save is deleted and the game returns to the title screen.

- **Exclusive HMs** – Each HM can only be taught to one Pokémon at a time. Two or more Pokémon cannot have the same HM simultaneously.

- **No Rematch** – It is not allowed to redo battles against NPCs or Rivals to improve results or level up Pokémon. Each encounter must be played only once.

- **Limited Healing Items** – Healing and recovery items can only be used during battles. It is prohibited to use them outside of combat to restore HP, PP, or status. In link battles, NO items are allowed.

- **Accidental Death Rule** – If a Pokémon dies accidentally during capture, you can no longer capture or fight Pokémon on that route.

- **No Exit Academies** – Upon entering an Academy or Dojo, you cannot leave until you defeat ALL TRAINERS. Win or die. Party is healed (no revive) before the Gym Leader battle.

- **One-Time Dungeons** – You may enter a dungeon only once, unless the story requires a revisit. A dungeon includes: any hideout, any cave, any building with trainers. (Forests are not considered dungeons.)

- **League Heal** – Before and after each battle in the Pokémon League, your party is healed (HP, PP, status cured, no revive) so each battle is fought at full potential.

- **Limited Healing Centers in Dungeons** – Healing centers present in dungeons (e.g., Rocket Hideout, SS Anne bed) can only be used once per dungeon. Healing from mandatory story events remains allowed.

- **No Shops** – You can only use items you pick up or receive from NPCs. Shops cannot sell healing or recovery items. Pokéballs, Repels, Evolution Stones, and TMs may still be purchased.

### Link Play Rules

- **Title Screen Lock** – NEW GAME and CONTINUE require an active link connection. The first link opponent becomes your rival.

- **Dominance Duel (MD3)** – Replaces NPC rival battles with link battles. Best of 3. Between rounds, players can reorder their party. Party is fully healed after each rival battle (revive included), but only healed (no revive) between MD3 rounds.

- **Pink Slip** – Only applies at the END of the MD3, not during individual rounds.

## How to Test

```sh
cd /c/dev/projects/pokemon/gen1recomp
love . --developer
```

## Validation

```sh
python tools/modkit.py validate mods/nuzlocke_on_rival --base imported
python tools/modkit.py lint mods/nuzlocke_on_rival
```

## Structure

```
mods/nuzlocke_on_rival/
├── main.lua              # Entry point
├── manifest.json         # Mod configuration
├── mod.card              # Metadata
├── src/
│   ├── state.lua         # Central state management
│   ├── rules.lua         # Rule registry
│   ├── rules/            # Solo rules
│   │   ├── capture.lua       # Limited Capture
│   │   ├── nickname.lua      # Mandatory Nickname
│   │   ├── death.lua         # Permanent Death + Ghost Sprite
│   │   ├── hm.lua            # Exclusive HMs
│   │   ├── rematch.lua       # No Rematch
│   │   ├── items.lua         # Limited Healing Items
│   │   ├── shops.lua         # No Shops (restricted purchases)
│   │   ├── academy.lua       # No Exit Academies + League Heal
│   │   ├── dungeon.lua       # One-Time Dungeons
│   │   ├── center_limit.lua  # Limited Centers in Dungeons
│   │   ├── link_validation.lua # Title Screen Lock
│   │   └── game_over.lua     # Game Over (placeholder)
│   └── link/             # Link play rules
│       ├── rival.lua         # My Rival (NPC rename)
│       ├── dominance.lua     # Dominance Duel (MD3)
│       ├── pink_slip.lua     # Pink Slip (placeholder)
│       └── negotiation.lua   # Negotiations (trade native)
└── tests/                # Tests
```

## Version

0.1.0
