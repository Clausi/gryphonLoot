# GryphonLoot

A World of Warcraft addon that improves looting: it marks the items in Blizzard's loot window and
adds their value, the free bag space and a "Loot All" button, shows who chose need, greed or pass
next to the roll frames, keeps the roll results in a small window and records your loot in a log.
The loot roll features came from GryphonFrames.

## Supported clients

| Client  | Interface | Status    |
| ------- | --------- | --------- |
| Forever | 16001     | Supported |

Other clients are not supported.

## Installation

Copy (or symlink) the `GryphonLoot` folder into the AddOns folder of the client:

```
World of Warcraft\_forever_\Interface\AddOns\GryphonLoot
```

## Structure

```
GryphonLoot.toc        Addon metadata and load order
Locales/enUS.lua       Base locale (every key), fallback for all languages
Locales/deDE.lua       German translation
Core/Init.lua          Namespace, saved variable defaults, module, command and event registry
Core/Util.lua          Chat output, debug and memory helpers, defaults merging
Core/Main.lua          Bootstrap: saved variables, module lifecycle, slash commands
Modules/LootRolls.lua  Shows the choices of the group at loot rolls and keeps the results in a window
Modules/LootWindow.lua Marks the items of the loot window, adds value, bag space and "Loot All"
Modules/LootLog.lua    Records the looted items and money and shows them in a window
Modules/Options.lua    Options page in the game settings ("/gryphonloot options")
Libs/                  Embedded libraries, not in the repo (fetched by the packager)
```

## Libraries

The packager embeds these libraries from the externals in `.pkgmeta`:

- [LibStub](https://www.wowace.com/projects/libstub) (public domain)
- [LibEditMode](https://github.com/p3lim-wow/LibEditMode) by p3lim: adds own frames to the Edit
  Mode. Its license allows embedding it unmodified into an addon; it stays under its own license
  (`Libs/LibEditMode/LICENSE.txt`), not under the MIT license of GryphonLoot.

## Releasing

1. Move the `[Unreleased]` entries in `CHANGELOG.md` to a new version section and bump
   `## Version` in `GryphonLoot.toc`, then merge that into `main`.
2. Tag the merged commit on `main` and push the tag:

   ```
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

The release workflow (`.github/workflows/release.yml`) runs luacheck, builds the package with the
[BigWigs packager](https://github.com/BigWigsMods/packager) and uploads it to
[CurseForge](https://www.curseforge.com/wow/addons/gryphon-loot) (project ID from
`X-Curse-Project-ID` in the TOC), [Wago Addons](https://addons.wago.io/addons/gryphonloot)
(`X-Wago-ID`) and as a GitHub release; WoWInterface once `X-WoWI-ID` is set. Game versions come
from `## Interface`. It needs the repository secrets `CF_API_KEY` (a CurseForge API token),
`WAGO_API_TOKEN` (a Wago Addons API key) and `WOWI_API_TOKEN` (a WoWInterface API token).

## Localization

All strings live in `Locales/`. Add new keys to `enUS.lua` first; other locales
only override what they translate. Missing keys fall back to English.

## Development

Lint with [luacheck](https://github.com/lunarmodules/luacheck). Place `luacheck.exe` in `.tools/`
(ignored by git) and run from the repo root:

```
./.tools/luacheck.exe .
```

## Slash commands

- `/gryphonloot` – help
- `/gryphonloot options` – open the addon options (also in Options > AddOns > GryphonLoot)
- `/gryphonloot version` – show version
- `/gryphonloot notify on|off` – automatic messages (login, loot log reset, hints) of the current
  character, default on
- `/gryphonloot rolls on|off` – show who chose need, greed or pass next to the roll frames for
  the current character, default on
- `/gryphonloot results on|off|test` – keep the results of loot rolls in a window for the
  current character, default on; `test` shows a made-up result (drag to move, corner to size, closing
  time in the options)
- `/gryphonloot log [on|off|reset]` – without argument shows or hides the loot log window; `on|off`
  turns recording on or off for the current character (default on), `reset` deletes the log (also
  with the button in the options, or on each login with the option "Reset at Login", default off)
- `/gryphonloot debug` – toggle debug output (after a `/reload`, also the memory each module keeps)

Modules add subcommands with `ns:RegisterCommand(name, handler, helpLines)`.

## Options

All options live in `Modules/Options.lua` (Esc > Options > AddOns > GryphonLoot), loaded after
the other modules. Proxy settings read and write `ns.db` and `ns.charDb` through the getters and
setters of the modules (e.g. `LootRolls:SetAutoClose`), so a change takes effect right away.
The page has one section per feature: loot window, loot rolls and loot log. Size, position and look
of the results window, and position and size of the loot log, are set in Edit Mode, per layout.
Opening the page by command is blocked in combat.

## License

[MIT](LICENSE)
