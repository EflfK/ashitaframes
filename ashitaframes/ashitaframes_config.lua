return {
    settings = {
        visible = true,
        locked = false,

        show_target = true,
        show_party = true,
        show_pet = true,
        show_alliance = false,
        show_empty_target = true,

        same_zone_dim = true,
        show_jobs = true,
        show_percent = true,
        show_tp = true,
        show_buffs = true,
        show_buff_reminders = true,
        show_target_debuffs = true,
        show_target_debuff_reminders = true,
        hide_buff_reminders_in_towns = true,
        buff_reminder_suppressed_zone_ids = { },
        max_buffs = 8,
        party_preview_size = 6,

        party_window_x = 36,
        party_window_y = 362,
        pet_window_x = 36,
        pet_window_y = 230,
        target_window_x = 36,
        target_window_y = 296,

        frame_width = 232,
        row_height = 56,
        row_gap = 5,
        opacity = 88,
        party_frame_width = 232,
        party_row_height = 56,
        party_row_gap = 5,
        party_opacity = 88,
        party_size_layouts = {
            [1] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [2] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [3] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [4] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [5] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [6] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
        },
        pet_frame_width = 232,
        pet_row_height = 56,
        pet_row_gap = 5,
        pet_opacity = 88,
        target_frame_width = 232,
        target_row_height = 56,
        target_row_gap = 5,
        target_opacity = 88,

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

