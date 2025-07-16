local style = {}

style.tree_node_sprite_dimensions = {
    width = 24,
    height = 24
}

style.calculator_window_dimensions = {
    width = 1200,
    padding = 10
}
style.calculator_window_titlebar_dimensions= {
    height = 24,
}
style.calculator_window_content_dimensions = {
    width = style.calculator_window_dimensions.width - 2 * style.calculator_window_dimensions.padding,
    height = 190,
    margin = 0
}
style.calculator_window_tree_dimensions = {
    width = style.calculator_window_dimensions.width - 2 * style.calculator_window_dimensions.padding,
    height = 500,
    margin = 0
}
style.calculator_window_dimensions = {
    width = style.calculator_window_dimensions.width,
    height = style.calculator_window_content_dimensions.height 
    + style.calculator_window_tree_dimensions.height 
    + style.calculator_window_titlebar_dimensions.height
    + 2 * style.calculator_window_dimensions.padding
    + 40, -- additional space for buttons and margins
    padding = style.calculator_window_dimensions.padding
}

return style