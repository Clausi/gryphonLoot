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
- Addon options in Options > AddOns > GryphonLoot, or with `/gryphonloot options`.
- Slash commands `/gryphonloot version`, `/gryphonloot notify on|off` and `/gryphonloot debug`.
