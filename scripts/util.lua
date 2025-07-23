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
    storage.calculator_last_picked_drill[player.index] = nil -- Initialize last picked drill
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