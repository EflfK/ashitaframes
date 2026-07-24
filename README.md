# AshitaFrames

Unit frame overlay for Ashita v4 on CatsEyeXI, with attended self-buff
cancellation.

AshitaFrames is an experimental UI addon intended to pair with native name
hiding addons such as `noname`. It draws compact party/alliance and target
frames using local Ashita memory-manager state, so the game world can stay
clean while important unit information remains visible elsewhere on screen.

## Current Scope

- Draws a draggable target frame with name, HP percent, distance when
  available, and observed check difficulty/level in the top-right label slot.
- Draws a separate draggable Battle Targets window for enemies claimed by or
  acting against the party. Each AshitaFrames-styled row shows HP, optional
  observed cast progress, observed debuff icons, and a highlight for the
  current target; the current target is sorted first.
- Integrates the installed MobDB zone database directly into monster target
  frames without requiring the MobDB addon itself to be loaded.
- Presents MobDB information as a compact three-row field card inside the target
  frame: centered behavior icons in the header, content-sized weak damage chips
  on the left and strong damage chips on the right, and drops/respawn in the
  footer.
- Damage chips show absolute modifier values and each side is ordered from the
  most effective damage option to the least effective from left to right.
- Mob drops use their real item icons without permanent labels; hovering an item
  reveals its name, stack size, and in-game description. Respawn time remains
  centered beside a small clock.
- Draws a draggable self frame for the local player.
- Draws draggable party frames for party members other than yourself, with
  optional alliance slots. Trust slots that linger in Ashita memory after
  zoning are hidden once they are no longer in your current zone.
- Highlights the self or party row temporarily selected by AshitaBars' attended
  party picker. AshitaFrames only consumes blocked, process-local
  `/ashitaui partyselect` UI-state events; it never chooses a target or sends
  the resulting gameplay command.
- Draws a draggable pet frame when your local player has an active pet, using
  the pet entity for name/HP/distance and Ashita pet state for MP and TP.
- Shows HP as the row background fill, with MP, TP, job/subjob, level, and
  same-zone dimming where Ashita exposes that data.
- Shows configurable cast bars on self, party, pet, target, and battle-target
  frames. The local player uses Ashita cast-bar memory; other units use
  observed cast starts with resource cast-time estimates. Enemy TP moves such
  as `Self-Destruct` use the packet/log "readies" event and a six-second fallback
  bar that clears as soon as the move completes, because FFXI does not send a
  per-move ready duration. Cast labels show the resolved spell, item, or TP-move
  name and append the observed target when available.
- Shows compact party status icons for every buff and debuff reported by Ashita
  status memory, plus observed party effect messages for trusts. Status icons
  use the game's native artwork and draw in a reserved left rail so
  HP/MP/TP/cast bars remain clear. Hovering any status icon shows its name and
  native in-game description.
- Shows compact missing-buff reminders for mapped buffs configured per current
  player job. Missing reminders flash with a crossed icon, and the rail count
  badge shows a hover tooltip listing the missing buffs. Active buffs show as
  normal icons. Trust reminders clear after observed gain messages and reset on
  zoning or party changes, even if another chat addon modifies or hides the
  native incoming line. On load, recent current-zone effect messages seed the
  observed state, and a bounded live chat-log tail keeps trust statuses updated
  after reloads and new effects. Protect and Shell remain the initially mapped
  missing-buff reminders.
- Monitors Signet on the self frame without spending a permanent icon slot.
  Healthy Signet stays hidden, Signet below the configured warning threshold
  flashes amber with its remaining time in the tooltip, and missing Signet
  flashes red. The default warning threshold is 30 minutes.
- Shows compact target-frame status rails: observed target buffs on the left
  and all packet-observed debuffs from spells and abilities on a right rail
  that expands into additional columns instead of clipping active effects.
  Missing target-debuff reminders only flash when the spell is learned, usable
  by the current main/sub job, and off cooldown. Dia, Paralyze, and Slow remain
  the initially mapped reminder set.
- Includes a persistent in-game configuration window for visibility, locking,
  sizing, opacity, self/party/pet/target display, party status display, target
  debuff display, missing-buff reminders, and alliance display.
- Right-clicking an active buff on the self frame removes that one status,
  matching the manual action available through FFXI's vanilla buff UI.
- Other than that attended self-buff action, it does not target, cast,
  click-cast, queue gameplay commands, write memory, or automate actions.

## Safety Boundary

The display remains in the CatsEyeXI T0/T2 lane, while manual self-buff
cancellation is a narrowly scoped T1 attended action:

- Allowed: local UI drawing, display-only party/target/entity information,
  local config toggles, and passive display of temporary addon-owned selection
  state.
- Active behavior: one right-click on one currently active self buff sends the
  same status-cancel request used by the vanilla UI. Party and target buffs
  cannot be clicked, missing-buff reminders cannot be clicked, and the status
  is revalidated immediately before the request is sent.
- Not allowed here: `/ma`, `/ja`, `/item`, `/target`, `/attack`, command
  queuing, arbitrary packet injection, input simulation, unattended behavior,
  timers that choose actions, or state-driven automation.

CatsEyeXI classifies on-demand status cancellation as T1 and requires each
active addon to be approved individually. Get CatsEyeXI staff approval for this
AshitaFrames version before normal use. If click-casting or frame-click
targeting is ever considered, treat that as a separate active-helper design and
obtain another policy review.

## Install

From this repository:

```powershell
.\install.ps1
```

The installer copies the addon and adds `/addon load ashitaframes` to
`Ashita\scripts\default.txt` if it is not already present. To install without
changing the startup script:

```powershell
.\install.ps1 -SkipAutoload
```

To load immediately in game:

```text
/addon load ashitaframes
```

Useful pairing:

```text
/addon load noname
```

`noname` handles hiding native overhead names locally. AshitaFrames only draws
replacement unit information in fixed UI frames.

## Commands

```text
/ashitaframes
/ashitaframes show
/ashitaframes hide
/ashitaframes toggle
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

Open the in-game configuration window:

```text
/ashitaframes config
```

The configuration window is organized into General, Self, Party, Pet, Target,
and Battle tabs. The Self, Party, Pet, Target, and Battle tabs each include that frame's
persisted on/off toggle (`show_self`, `show_party`, `show_pet`, or
`show_target`; the Battle toggle is `show_battle_targets`) plus its layout
controls. The Party tab includes Protect/Shell
reminders. The Target tab includes Dia, Paralyze, and Slow reminders plus the
MobDB integration toggle. AshitaFrames reads MobDB's installed zone data and
icons; `/addon load mobdb` is not required.
The Battle tab controls the maximum tracked enemies, observed debuff icons,
layout, opacity, HP/cast bars, and text thresholds. While configuration is
open, it renders a two-enemy preview so the Battle Targets window can be
positioned and styled outside combat.
Use Save to write the current window layout and reminder settings to
`Ashita/config/addons/ashitaframes/ashitaframes_config.lua`. If an older
`Ashita/addons/ashitaframes/ashitaframes_config.lua` exists and the normal
config file does not, AshitaFrames migrates the legacy file on load. Self,
Party, Pet, and Target frame width, height, row gap, opacity, HP/MP/TP/cast bar
heights, MP bar, TP bar, cast bar, and MP/TP/cast text thresholds are configured
independently. HP, MP, TP, and cast text is drawn inside its own bar, and bar
heights are clamped so they cannot be shorter than the current text height. HP
text shows percent plus current/max when that data is available. Width controls
allow frames up to 750 pixels wide. Party frame layout is also configured separately
for total party sizes 1 through 6, including columns and rows for stacking party
members into grids; while the configuration window is open, the party frame
fills missing non-self rows with preview members for the selected size. Reminder
options are filtered to spells your current main/sub job can actually cast and
that your character has learned. Missing target-debuff reminders are also hidden
while the spell is on cooldown. Missing party-buff reminder flashes are hidden in
towns by default; the config window can also suppress or allow the current
non-town zone. Locked frames hide their title bars and window-shell backgrounds
so only the individual frame rows are drawn; the configuration window keeps its
normal container.

Manual config is still supported:

Edit:

```text
Ashita/config/addons/ashitaframes/ashitaframes_config.lua
```

The defaults are intentionally conservative:

```lua
return {
    settings = {
        visible = true,
        locked = false,
        show_self = true,
        show_target = true,
        show_battle_targets = true,
        show_party = true,
        show_pet = true,
        show_alliance = false,
        show_empty_target = true,
        same_zone_dim = true,
        show_jobs = true,
        show_percent = true,
        show_mp = true,
        show_tp = true,
        show_cast = true,
        show_buffs = true,
        show_buff_reminders = true,
        show_target_debuffs = true,
        show_target_debuff_reminders = true,
        show_target_mobdb = true,
        show_battle_target_debuffs = true,
        hide_buff_reminders_in_towns = true,
        buff_reminder_suppressed_zone_ids = { },
        signet_reminder_enabled = true,
        signet_warning_minutes = 30,
        max_buffs = 8,
        party_preview_size = 6,
        battle_target_max_entries = 8,
        mp_text_threshold = 1,
        tp_text_threshold = 1000,
        cast_text_threshold = 1,
        self_window_x = 36,
        self_window_y = 164,
        party_window_x = 36,
        party_window_y = 362,
        pet_window_x = 36,
        pet_window_y = 230,
        target_window_x = 36,
        target_window_y = 296,
        battle_window_x = 285,
        battle_window_y = 296,
        frame_width = 232,
        height = 56,
        row_height = 56,
        row_gap = 5,
        opacity = 88,
        hp_bar_height = 38,
        mp_bar_height = 18,
        tp_bar_height = 18,
        cast_bar_height = 18,
        self_frame_width = 232,
        self_height = 56,
        self_row_height = 56,
        self_row_gap = 5,
        self_opacity = 88,
        self_hp_bar_height = 38,
        self_mp_bar_height = 18,
        self_tp_bar_height = 18,
        self_cast_bar_height = 18,
        self_show_mp = true,
        self_show_tp = true,
        self_show_cast = true,
        self_mp_text_threshold = 1,
        self_tp_text_threshold = 1000,
        self_cast_text_threshold = 1,
        party_frame_width = 232,
        party_height = 56,
        party_row_height = 56,
        party_row_gap = 5,
        party_opacity = 88,
        party_hp_bar_height = 38,
        party_mp_bar_height = 18,
        party_tp_bar_height = 18,
        party_cast_bar_height = 18,
        party_show_mp = true,
        party_show_tp = true,
        party_show_cast = true,
        party_mp_text_threshold = 1,
        party_tp_text_threshold = 1000,
        party_cast_text_threshold = 1,
        party_size_layouts = {
            [1] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88, columns = 1, rows = 1 },
            [2] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88, columns = 1, rows = 1 },
            [3] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88, columns = 1, rows = 2 },
            [4] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88, columns = 1, rows = 3 },
            [5] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88, columns = 1, rows = 4 },
            [6] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88, columns = 1, rows = 5 },
        },
        pet_frame_width = 232,
        pet_height = 56,
        pet_row_height = 56,
        pet_row_gap = 5,
        pet_opacity = 88,
        pet_hp_bar_height = 38,
        pet_mp_bar_height = 18,
        pet_tp_bar_height = 18,
        pet_cast_bar_height = 18,
        pet_show_mp = true,
        pet_show_tp = true,
        pet_show_cast = true,
        pet_mp_text_threshold = 1,
        pet_tp_text_threshold = 1000,
        pet_cast_text_threshold = 1,
        target_frame_width = 232,
        target_height = 56,
        target_row_height = 56,
        target_row_gap = 5,
        target_opacity = 88,
        target_hp_bar_height = 38,
        target_mp_bar_height = 18,
        target_tp_bar_height = 18,
        target_cast_bar_height = 18,
        target_show_mp = false,
        target_show_tp = false,
        target_show_cast = true,
        target_mp_text_threshold = 1,
        target_tp_text_threshold = 1000,
        target_cast_text_threshold = 1,
        battle_frame_width = 232,
        battle_height = 56,
        battle_row_height = 56,
        battle_row_gap = 5,
        battle_opacity = 88,
        battle_hp_bar_height = 38,
        battle_mp_bar_height = 18,
        battle_tp_bar_height = 18,
        battle_cast_bar_height = 18,
        battle_show_mp = false,
        battle_show_tp = false,
        battle_show_cast = true,
        battle_mp_text_threshold = 1,
        battle_tp_text_threshold = 1000,
        battle_cast_text_threshold = 1,

        buff_reminders = {
            default = {
                enabled = true,
                self = true,
                players = true,
                trusts = true,
                buffs = { 'protect', 'shell' },
            },

            BST = {
                enabled = true,
                self = true,
                players = true,
                trusts = true,
                buffs = { 'protect' },
            },
        },

        target_debuff_reminders = {
            default = {
                enabled = true,
                debuffs = { 'dia', 'paralyze', 'slow' },
            },
        },
    },
}
```

The base `frame_width`, `height`, `row_height`, `row_gap`, `opacity`,
`hp_bar_height`, `mp_bar_height`, `tp_bar_height`, `cast_bar_height`, `show_mp`,
`show_tp`, `show_cast`, `mp_text_threshold`, `tp_text_threshold`, and
`cast_text_threshold` keys are kept
as fallbacks for older configs. New saves write separate `self_*`, `party_*`,
`pet_*`, and `target_*` layout and bar values; party frame saves also write the
`party_size_layouts` table for size-specific positions, dimensions, columns,
and rows.

`buff_reminders` is keyed by your current main job. Each profile can enable or
disable reminders for yourself (`self`), other players (`players`), and trusts
(`trusts`). Supported reminder keys are currently `protect` and `shell`;
configured reminders only display when the spell is learned and usable on your
current main/sub job.

`hide_buff_reminders_in_towns` hides missing-buff flashes in town and safe hub
zones. Add zone ids to `buff_reminder_suppressed_zone_ids` to hide missing
reminders in additional zones.

`target_debuff_reminders` is keyed by your current main job. Active debuffs
applied by players, trusts, pets, or monsters are observed from incoming action
and wear-off packets and shown with their native status icons. Because FFXI
does not expose a complete target-status snapshot to the client, effects already
active before AshitaFrames loads may not appear until they are applied again.
AshitaFrames passively reads the original packet even when a combat-log addon
such as SimpleLog blocks or rewrites it for display; AshitaFrames does not
change the packet or its blocked state.
Supported target
debuff reminder keys are currently `dia`, `paralyze`, and `slow`; configured
reminders only display on attackable targets when the spell is learned, usable
on your current main/sub job, and not on cooldown. Active target debuff icons
are display-only observed state.

## Development

Validate the safe surface checks:

```powershell
.\scripts\validate.ps1
```

