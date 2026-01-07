# Hardcore Stat Companion

Hardcore Stat Companion is a WoW Classic Era addon that tracks Hardcore-focused character and account statistics and shows them in a small on-screen overlay.

## Features

- On-screen overlay with configurable rows, scale, background opacity, and text color
- Drag-to-move overlay (with optional position lock) and position persistence
- Blizzard Interface Options panel integration
- Minimap button:
  - Left-click: toggle overlay
  - Right-click: open options
  - Drag: move button around the minimap
- Account-wide tracking:
  - Total deaths (all characters)
  - Deaths for current class
  - Max level (account) and max level (current class)
- Combat/stat tracking (best-effort within Classic constraints):
  - Tagged kill credit and classification (elite/rare/world boss/dungeon boss) using cached unit data
  - Consumable usage (healing/mana potions, bandages, grenades, target dummies) with localized matching
  - Close escapes heuristic
  - Jumps heuristic
  - Map opened count

## Commands

- `/hsc` — Open/close the standalone configuration window.

## Data Storage

SavedVariables are stored in `HardcoreStatCompanionDB`:

- Per-character: `HardcoreStatCompanionDB.global.characters[realm-name].stats`
- Account-wide: `HardcoreStatCompanionDB.global.accountStats`
- Settings: `HardcoreStatCompanionDB.global.settings`

## Development Notes

- This addon targets Classic Era (the `.toc` Interface version is set accordingly).
- Some stats rely on heuristics and combat log limitations; behavior can vary by locale and combat log event availability.

## Honorable Mention
Inspired by BonniesDadTV’s Ultrahardcore Addon