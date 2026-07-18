# AshitaFrames

Read-only unit frame overlay for Ashita v4 on CatsEyeXI.

AshitaFrames is an experimental UI addon intended to pair with native name
hiding tools such as the `Nameplate` plugin or `noname`. It draws compact
party/alliance and target frames, plus overhead HP bars projected over visible
entities, using local Ashita memory-manager state.

## Current Scope

- Draws a draggable target frame with name, HP percent, and distance when
  available.
- Draws draggable party frames for the first party by default, with optional
  alliance slots.
- Draws compact overhead HP bars for visible entities, color-coding current
  target, party/trust members, claimed units, and neutral units.
- Shows HP, MP, TP, job/subjob, level, and same-zone dimming where Ashita
  exposes that data.
- Includes an in-game configuration window for visibility, locking, sizing,
  opacity, overhead-bar distance/count/size, and alliance display.
- Provides local UI commands only. It does not target, cast, click-cast, send
  gameplay commands, inject packets, write memory, or automate actions.

## Safety Boundary

This addon is display-only. Keep it in the CatsEyeXI T0/T2 lane:

- Allowed: local UI drawing, display-only party/target/entity information,
  local config toggles.
- Not allowed here: `/ma`, `/ja`, `/item`, `/target`, `/attack`, command
  queuing, packet injection, input simulation, unattended behavior, timers that
  choose actions, or state-driven automation.

If click-casting or frame-click targeting is ever considered, treat that as a
separate active-helper design and get CatsEyeXI policy review before normal use.

## Install

From this repository:

```powershell
.\install.ps1
```

In game:

```text
/addon load ashitaframes
```

To approximate true name replacement, load the existing Nameplate plugin and
hide native nameplates:

```text
/load Nameplate
/nameplate mode none
```

Less aggressive pairing:

```text
/addon load noname
```

`Nameplate`/`noname` handle hiding native overhead text locally. AshitaFrames
draws replacement overhead bars; it does not patch the native name renderer.
The overhead bars are an ImGui overlay, so they are not depth-tested against
walls. Keep `nameplate_max_distance` conservative if a crowded zone shows bars
for rendered actors around corners.

## Commands

```text
/ashitaframes
/ashitaframes show
/ashitaframes hide
/ashitaframes toggle
/ashitaframes plates on
/ashitaframes plates off
/ashitaframes plates toggle
/ashitaframes plates names
/ashitaframes lock
/ashitaframes unlock
/ashitaframes config
/ashitaframes reload
/ashitaframes status
```

Short alias:

```text
/aframes
```

## Configure

Edit:

```text
ashitaframes/ashitaframes_config.lua
```

The defaults are intentionally conservative:

```lua
return {
    settings = {
        visible = true,
        locked = false,
        show_target = true,
        show_party = true,
        show_alliance = false,
        show_empty_target = true,
        show_nameplates = true,
        nameplate_show_self = false,
        nameplate_show_names = false,
        nameplate_scale_by_distance = true,
        nameplate_max_distance = 35,
        nameplate_max_count = 28,
        nameplate_width = 72,
        nameplate_height = 8,
        nameplate_y_offset = 2.35,
        same_zone_dim = true,
        show_jobs = true,
        show_percent = true,
        show_tp = true,
        party_window_x = 36,
        party_window_y = 362,
        target_window_x = 36,
        target_window_y = 296,
        frame_width = 232,
        row_height = 42,
        row_gap = 5,
        opacity = 88,
    },
}
```

Runtime changes made in the config window are not persisted yet. When a layout
feels right, copy the positions and sizing shown by `/ashitaframes status` into
`ashitaframes_config.lua`.

## Development

Validate the safe surface checks:

```powershell
.\scripts\validate.ps1
```

