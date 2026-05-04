# Sprite Notes

This document records the upstream eSheep frame sequences that are useful in Baaaa.

The source sheet is `Sources/Baaaa/Resources/esheep.png`. It is a `16 x 11` grid of `40 x 40` tiles, indexed left-to-right and then top-to-bottom.

## Currently Ported

### Walk

- Upstream animation: `walk` (`id=1`)
- Frames: `2, 3`
- Repeat: `20` from `0`

### Fall

- Upstream animation: `fall` (`id=5`)
- Frames: `133`
- Repeat: `20` from `0`

### Drag

- Upstream animation: `drag` (`id=4`)
- Frames: `42, 43, 43, 42, 44, 44`
- Local simplified loop: `42, 43, 44`

### Soft Landing / Dazed Recovery

- Upstream animation: `fall soft` (`id=9`)
- Upstream frames: `133, 133, 133, 133, 49, 13, 12, 6`
- Local port focuses on the recovery tail: `49, 13, 12, 13, 12, 6`

### Blink

- Chosen by hand from the top row of the sprite sheet
- Single blink: `7, 8, 7`
- Double blink: `7, 8, 7, 3, 7, 8, 7`

## Next Idle Behaviours

These are the upstream sequences prepared for Baaaa idle pauses.

At the moment, Baaaa is intentionally running only one of them live at a time for visual verification. The current live selection is `Head Turn`.

### 1. Head Turn

- Upstream animations: `rotate1a` (`id=2`) and `rotate1b` (`id=3`)
- Upstream frames: `3, 9, 10` then `10, 9, 3`
- Local sequence: `9, 10, 10, 9, 3`
- Visual effect: a quick glance over the shoulder during a long pause

### 2. Look Down

- Upstream animation: `look_down` (`id=43`)
- Upstream frames: `6, 78, 78, 78, 79, 80, 79, 78, 78, 78, 78, 78`
- Local sequence: `78, 78, 78, 79, 80, 79, 78, 78, 78, 78, 78, 6`
- Trigger: when the sheep is paused near the leading edge of a surface

### 3. Pee / Wee

- Upstream animations: `pissa` (`id=11`) and `pissb` (`id=12`)
- Upstream entry frames: `3, 12, 13, 103, 104, 105, 106`
- Upstream repeat: `5+random/10` from `5`
- Upstream exit frames: `104, 105, 104, 104, 103, 13, 12`
- Local sequence: entry + a small bounded number of `105, 106` loops + exit + `3`
- Visual effect: clearly reads as the sheep having a wee, not scratching
- Note: this is not currently enabled live

### 4. Sleepy Nod

- Upstream animations: `sleep2a` (`id=17`) and `sleep2b` (`id=18`)
- Upstream entry frames: `3, 6, 7, 8, 8, 7, 8, 8`
- Upstream repeat: `random/10+20` from `6`
- Upstream exit frames: `8, 7, 6`
- Local sequence: `6, 7, 8, 8` + a bounded number of `7, 8, 8` loops + `8, 7, 6, 3`
- Visual effect: a brief drowsy pause during a long idle
- Note: this is not currently enabled live

## Other Good Candidates

These are worth porting later.

### Scratchier Idle

- `kill` (`id=13`): `3, 96, 96`
- A tiny emphatic “hmph” pose, probably useful as a reaction

### Lie-Down Sleep

- `sleep1a` (`id=15`): `3, 107, 108, 107, 108, 107, 31, 32, 33, 0, 1`
- `sleep1b` (`id=16`): `0, 80, 79, 78, 77, 37, 38, 39, 38, 37, 6`
- Best bigger upgrade for long rests

### Run Burst

- `run_begin` (`id=35`): `2, 3, 2, 5, 4, 5, 4, 5`
- `run` (`id=7`): `5, 4, 4`
- `run_end` (`id=36`): `5, 4, 5, 4, 5, 3, 2, 3, 2, 3`
- Good for “zoomies”

### Jump

- `jump` (`id=25`): `76, 30, 30, 30, 30, 23, 23, 23, 23, 23, 24, 24, 24, 24, 77`
- Useful if Baaaa grows deliberate ledge-jump behaviour

### Nibble

- `eat` (`id=26`): `6, 6, 6, 6, 58, 59, 59, 60, 61, 60, 61, 6`
- Good rare idle behaviour

## Environment-Coupled Upstream Sets

These are interesting but need more spatial logic than Baaaa currently has.

- `vertical_walk_up` (`id=37`): `31, 30, 15, 16`
- `top_walk` (`id=38`): `16, 17, 28`
- `top_walk2` (`id=39`): `98, 97`
- `top_walk3` (`id=40`): `97, 97`
- `vertical_walk_down` (`id=41`): `19, 20`
- `vertical_walk_over` (`id=42`): `24, 6, 6, 6, 6, 6`
- `jump_down` / `jump_down2` / `jump_down3` (`id=44-46`)
- `walk_win2`, `walk_task2`, `fall_wina` through `fall_wind` (`id=49-54`)

These mostly depend on explicit walls, ceilings, taskbar edges, or multi-stage edge traversal.
