local gui = require("gui")
local calculator = require("calculator")
local tree = require("tree")
local style = require("style")

local M = {}

function M.register()    
    -- This function is called when the mod is loaded and the game starts or a save is loaded.
    script.on_init(function()   
        if not global then global = {} end
        global.calculator_recipies_filter_enabled = {}
        -- Create the GUI button for all existing players
        for _, player in pairs(game.players) do
            gui.create_calculator_button(player)
        end
    end)

    -- This function is called when a player joins the game.
    script.on_event(defines.events.on_player_joined_game, function(event)
        local player = game.get_player(event.player_index)
        if player then
            gui.create_calculator_button(player)
            global.calculator_recipies_filter_enabled[player.index] = true
        end
    end)

    -- Handle checkbox state change to update filters_enabled per player
    script.on_event(defines.events.on_gui_checked_state_changed, function(event)
        local element = event.element
        if element and element.name == "exclude_undiscovered_recipes" then
            local player = game.get_player(event.player_index)
            if player then
                local prev_state = global.calculator_recipies_filter_enabled[player.index]
                if prev_state ~= element.state then
                    global.calculator_recipies_filter_enabled[player.index] = element.state
                    gui.open_calculator_gui(player)
                end
            end
        end
    end)

    -- Handle custom input to open calculator window (Ctrl+C)
    script.on_event("custom-input-resource-calculator-open", function(event)
        local player = game.get_player(event.player_index)
        if player then
            local frame = player.gui.screen.resource_calculator_frame
            if frame then
                frame.destroy()
            else
                gui.open_calculator_gui(player)
            end
        end
    end)


    -- Handle the click event for the calculator button
    script.on_event(defines.events.on_gui_click, function(event)
        local element = event.element
        -- If the clicked element is the calculator button, open the GUI
        if element and element.name == "resource_calculator_button" then
            local player = game.get_player(event.player_index)
            if player then
                gui.open_calculator_gui(player)
            end
        -- If the clicked element is the confirm button, process the input
        elseif element and element.name == "resource_calculator_confirm_button" then
            local player = game.get_player(event.player_index)
            if player then
                -- Find the frame in gui.screen
                local frame = player.gui.screen.resource_calculator_frame
                if frame then
                    local item_picker = frame.children[2].children[2].resource_calculator_item_picker
                    local number_input = frame.children[2].children[2].resource_calculator_number_input
                    local item = item_picker and item_picker.elem_value or nil
                    local amount = number_input and tonumber(number_input.text) or 1
                    
                    if prototypes == nil then
                        player.print("'prototypes' object not available.")
                        return
                    end
                    
                    if item ~= nil and amount ~= nil then
                        player.print("Calculating for: " .. item .. " at " .. amount .. " / second")
                        local recipe_results = calculator.calculate_requirements(item, amount, 1)
                        local result_label_name = "resource_calculator_result_label"
                        local sum_result_label_name = "resource_calculator_sum_result_label"
                        local sum_ingredients_table = {}
                        -- Sum the requirements
                        if recipe_results.ingredients then
                            for _, ingredient in pairs(recipe_results.ingredients) do
                                calculator.sum_requirements(ingredient, sum_ingredients_table)
                            end
                        end
                        -- Remove previous result labels/tree if present
                        local content_flow = frame.children[2]
                        
                        for _, child in pairs(content_flow.children) do
                            if child.name == result_label_name or child.name == sum_result_label_name or child.name == "resource_calculator_result_tree" then
                                child.destroy()
                            end
                        end
                        
                        tree.add_recipe_tree(content_flow, recipe_results, sum_ingredients_table)
                    else
                        player.print("Please select an item and enter a valid number.")
                    end
                end
            end
        -- If the clicked element is the close button, close the GUI
        elseif element and element.name == "resource_calculator_close_button" then
            local player = game.get_player(event.player_index)
            if player then
                local frame = player.gui.screen.resource_calculator_frame
                if frame then
                    frame.destroy()
                end
            end
        end
    end)

    -- This function is called when a player leaves the game (useful for cleaning up player-specific GUI elements)
    script.on_event(defines.events.on_player_left_game, function(event)
        local player = game.get_player(event.player_index)
        if player then
            local gui = player.gui
            local button_name = "resource_calculator_button"
            local frame_name = "resource_calculator_frame"
            if gui.top[button_name] then
                gui.top[button_name].destroy()
            end
            if gui.screen[frame_name] then
                gui.screen[frame_name].destroy()
            end
        end
    end)
end 

return M