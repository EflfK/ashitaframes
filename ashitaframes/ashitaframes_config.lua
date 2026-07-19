return {
    settings = {
        visible = true,
        locked = false,

        show_target = true,
        show_party = true,
        show_alliance = false,
        show_empty_target = true,

        same_zone_dim = true,
        show_jobs = true,
        show_percent = true,
        show_tp = true,
        show_buffs = true,
        show_buff_reminders = true,
        max_buffs = 8,

        party_window_x = 36,
        party_window_y = 362,
        target_window_x = 36,
        target_window_y = 296,

        frame_width = 232,
        row_height = 56,
        row_gap = 5,
        opacity = 88,

        buff_reminders = {
            default = {
                enabled = false,
                self = true,
                players = true,
                trusts = true,
                buffs = { },
            },

            BST = {
                enabled = true,
                self = true,
                players = true,
                trusts = true,
                buffs = { 'protect' },
            },
        },
    },
}

