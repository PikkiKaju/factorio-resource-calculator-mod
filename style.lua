-- Style definitions for the GUI
local style = {}

style.tree_node_sprite_dimensions = {
    width = 24,
    height = 24
}

style.calculator_window_dimensions = {
    width = 800,
    height = 600
}
style.calculator_window_tree_dimensions = {
    width = style.calculator_window_dimensions.width - 30,
    height = style.calculator_window_dimensions.height - 200
}

return style