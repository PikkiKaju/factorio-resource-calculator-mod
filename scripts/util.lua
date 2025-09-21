local style = require("style")
local M = {}

-- Initialize global storage if it doesn't exist
function M.init_globals()
    if not storage then storage = {} end
    storage.calculator_recipies_filter_enabled = {}
    storage.calculator_compact_mode_enabled = {}
    storage.calculator_raw_ingredients_mode_enabled = {}
    storage.calculator_tree_mode = {}
    storage.calculator_last_picked_item = {}
    storage.calculator_last_picked_production_rate = {}
    storage.calculator_last_picked_assembler = {}
    storage.calculator_last_picked_furnace = {}
    storage.calculator_last_picked_drill = {}
    storage.calculator_last_calculated_info = {}
    storage.calculator_window_width = {}
    storage.calculator_tree_height = {}
    storage.calculator_window_size_mode = {} -- "small" | "full"
end


-- Initialize global variables for a specific player
function M.init_globals_for_player(player)
    storage.calculator_recipies_filter_enabled[player.index] = player.mod_settings["calculator-exclude-undiscovered-recipes"].value
    storage.calculator_compact_mode_enabled[player.index] = player.mod_settings["calculator-compact-mode"].value
    storage.calculator_raw_ingredients_mode_enabled[player.index] = player.mod_settings["calculator-raw-ingredients-mode"].value
    if player.mod_settings["calculator-tree-mode"].value == "Graphical" then
        storage.calculator_tree_mode[player.index] = 2 -- Graphical mode
    else
        storage.calculator_tree_mode[player.index] = 1 -- Text mode
    end
    storage.calculator_last_picked_item[player.index] = nil -- Initialize last picked item
    storage.calculator_last_picked_production_rate[player.index] = 1 -- Initialize last picked amount
    storage.calculator_last_picked_assembler[player.index] = nil -- Initialize last picked assembler
    storage.calculator_last_picked_furnace[player.index] = nil  -- Initialize last picked furnace
    storage.calculator_last_picked_drill[player.index] = nil         -- Initialize last picked drill
    storage.calculator_last_calculated_info[player.index] = nil -- Initialize last calculated info
    -- Initialize window sizing with defaults if not set
    if storage.calculator_window_width[player.index] == nil then
        storage.calculator_window_width[player.index] = style.calculator_window_dimensions.width
    end
    if storage.calculator_tree_height[player.index] == nil then
        storage.calculator_tree_height[player.index] = style.calculator_window_tree_dimensions.height
    end
    if storage.calculator_window_size_mode[player.index] == nil then
        storage.calculator_window_size_mode[player.index] = "small"
    end
end

function M.find_prototype_by_name(name)
    local prototype_types = { "item", "fluid", "equipment" } -- "entity", 
    for _, proto_type in ipairs(prototype_types) do
        if prototypes[proto_type] and prototypes[proto_type][name] then
            return prototypes[proto_type][name]
        end
    end
    return nil
end

return M