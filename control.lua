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

-- Register events (delegated to events.lua)
events.register()