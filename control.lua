local gui = require("scripts.gui")
local events = require("scripts.events")
local util = require("scripts.util")


script.on_init(function()
    -- Initialize global variables if they don't exist
    util.init_globals()

    -- Create the GUI button for all existing players
    for _, player in pairs(game.players) do
        gui.create_calculator_button(player)
        util.init_globals_for_player(player)
    end
end)

script.on_load(function()
    
end)

script.on_configuration_changed(function(data)
    -- Always ensure global.storage exists
    if storage == nil then
        storage = {}
    end
    -- Always ensure each storage.* table exists
    if storage.calculator_recipies_filter_enabled == nil then
        storage.calculator_recipies_filter_enabled = {}
    end
    if storage.calculator_compact_mode_enabled == nil then
        storage.calculator_compact_mode_enabled = {}
    end
    if storage.calculator_raw_ingredients_mode_enabled == nil then
        storage.calculator_raw_ingredients_mode_enabled = {}
    end
    if storage.calculator_tree_mode == nil then
        storage.calculator_tree_mode = {}
    end
    if storage.calculator_last_picked_item == nil then
        storage.calculator_last_picked_item = {}
    end
    if storage.calculator_last_picked_production_rate == nil then
        storage.calculator_last_picked_production_rate = {}
    end
    if storage.calculator_last_picked_assembler == nil then
        storage.calculator_last_picked_assembler = {}
    end
    if storage.calculator_last_picked_furnace == nil then
        storage.calculator_last_picked_furnace = {}
    end
    if storage.calculator_last_picked_drill == nil then
        storage.calculator_last_picked_drill = {}
    end

    -- Recreate the GUI button for all players
    for _, player in pairs(game.players) do
        gui.create_calculator_button(player)
        util.init_globals_for_player(player)
    end
end)

-- Register events (delegated to events.lua)
events.register()
