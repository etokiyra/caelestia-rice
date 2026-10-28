local vars = require("variables")

hl.config({
    decoration = {
        rounding = vars.windowRounding,
        rounding_power = vars.windowRoundingPower,

        active_opacity   = 1,
        inactive_opacity = 1,

        dim_inactive = true,
        dim_strength = 0.12,
        dim_special  = 0.22,

        blur = {
            enabled           = vars.blurEnabled,
            xray              = vars.blurXray,
            special           = vars.blurSpecialWs,
            ignore_opacity    = true, -- Allows opacity blurring
            new_optimizations = true,
            popups            = vars.blurPopups,
            input_methods     = vars.blurInputMethods,
            size              = vars.blurSize,
            passes            = vars.blurPasses,

            -- Frosted glass tuning
            vibrancy          = 0.22,
            vibrancy_darkness = 0.18,
            contrast          = 0.96,
            brightness        = 0.88,
            noise             = 0.018,
        },

        shadow = {
            enabled      = vars.shadowEnabled,
            range        = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color        = vars.shadowColour,
        },
    },
})
