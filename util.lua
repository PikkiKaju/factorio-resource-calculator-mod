local M = {}

function M.init_globals()
    -- Initialize storage variables if they don't exist
    if not storage then storage = {} end
    storage.calculator_recipies_filter_enabled = {}
    storage.calculator_compact_mode_enabled = {}
    storage.calculator_raw_ingredients_mode_enabled = {}
    storage.calculator_tree_mode = {}
    storage.calculator_last_picked_item = {}
    storage.calculator_last_picked_production_rate = {}
end

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
end

return M