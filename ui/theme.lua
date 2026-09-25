local Theme = {
    virtualWidth = 1920,
    virtualHeight = 1080,
    colors = {
        charcoal = {0.035, 0.053, 0.067, 1},
        surface = {0.066, 0.094, 0.115, 0.97},
        raised = {0.10, 0.14, 0.17, 0.98},
        inset = {0.035, 0.055, 0.071, 0.96},
        metal = {0.24, 0.30, 0.33, 1},
        gold = {0.77, 0.62, 0.39, 1},
        goldDim = {0.40, 0.35, 0.27, 1},
        cyan = {0.30, 0.75, 0.89, 1},
        red = {0.90, 0.34, 0.34, 1},
        purple = {0.70, 0.48, 0.88, 1},
        green = {0.33, 0.78, 0.52, 1},
        text = {0.94, 0.96, 0.97, 1},
        muted = {0.67, 0.73, 0.77, 1},
        shadow = {0.01, 0.02, 0.03, 0.56},
    },
    border = {thin = 1, regular = 1.5, focus = 2},
    spacing = {xs = 4, sm = 8, md = 12, lg = 18, xl = 24},
    radius = {small = 4, medium = 7, large = 10},
    typography = {tiny = 12, small = 14, regular = 17, medium = 22, title = 28},
    glow = {normal = 0.12, hover = 0.25, selected = 0.38},
    shadows = {x = 3, y = 5, alpha = 0.5},
}

function Theme.accent(variant)
    return Theme.colors[variant or "gold"] or Theme.colors.gold
end

function Theme.buttonVariant(btn)
    if btn.variant then return btn.variant end
    if btn.color == Theme.colors.red then return "red" end
    if btn.color == Theme.colors.green then return "green" end
    if btn.color == Theme.colors.purple then return "purple" end
    if btn.color == Theme.colors.gold then return "gold" end
    local id = tostring(btn.id or "")
    if id:find("quit") or id:find("abandon") or id:find("discard") or id:find("delete") then return "red" end
    if id:find("setting") or id:find("option") then return "purple" end
    return btn.menuStyle and "gold" or "cyan"
end

return Theme
