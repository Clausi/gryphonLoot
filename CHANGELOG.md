# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

First version, for WoW Forever. The loot roll features moved here from GryphonFrames.

### Added

- Loot rolls: a panel next to each roll frame shows who chose need, greed or pass
  (`/gryphonloot rolls on|off`), and a small scrolling window keeps the rolls grouped by item
  (`/gryphonloot results on|off|test`), both per character and on by default. A roll already
  shows in the window after your own choice, with the players still to choose. The window can be
  moved and sized with the mouse, also in combat, or in Edit Mode, and can close by itself after a
  set time. Edit Mode also sets padding, opacity, background, text size, item icons and class
  colors, per layout, and shows a sample while the window is empty.
- Loot window: the icon of each item shows its item level (equipment), a green arrow for an
  upgrade over the equipped item and a red tint if you cannot use it. A bar below the window
  shows the vendor value of the items, the free bag slots (red if not everything fits) and a
  "Loot All" button. Each part can be turned off in the options, per character.
- Loot log: records the looted items, also won rolls, and money per character until it is reset.
  A window shows it with the vendor value (`/gryphonloot log`, `/gryphonloot log on|off|reset`);
  it can be moved and sized with the mouse or in Edit Mode. It can be reset in the options or
  by command, and the option "Reset at Login" empties it on each login.
- Addon options in Options > AddOns > GryphonLoot, or with `/gryphonloot options`.
- Slash commands `/gryphonloot version`, `/gryphonloot notify on|off` and `/gryphonloot debug`.
