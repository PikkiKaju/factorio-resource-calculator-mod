local gui = require("gui")
local calculator = require("calculator")
local tree = require("tree")
local style = require("style")

local M = {}

function M.register()    
    -- This function is called when the mod is loaded and the game starts or a save is loaded.
    script.on_init(function()   
        -- Initialize global variables if they don't exist
        if not global then global = {} end
        global.calculator_recipies_filter_enabled = {}
        global.calculator_compact_mode_enabled = {}
        global.calculator_raw_ingredients_mode_enabled = {}
        global.calculator_tree_mode = {}
        global.calculator_last_picked_item = {}
        global.calculator_last_picked_production_rate = {}

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
            global.calculator_recipies_filter_enabled[player.index] = false
            global.calculator_compact_mode_enabled[player.index] = true
            global.calculator_raw_ingredients_mode_enabled[player.index] = false
            global.calculator_tree_mode[player.index] = 2 -- Default to text mode
            global.calculator_last_picked_item[player.index] = nil -- Initialize last picked item
            global.calculator_last_picked_production_rate[player.index] = 1 -- Initialize last picked amount
        end
    end)

    -- Handle checkbox state change
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
        elseif element and element.name == "compact_mode_checkbox" then
            local player = game.get_player(event.player_index)
            if player then
                local prev_state = global.calculator_compact_mode_enabled[player.index]
                if prev_state ~= element.state then
                    global.calculator_compact_mode_enabled[player.index] = element.state
                    gui.open_calculator_gui(player)
                end
            end
        elseif element and element.name == "raw_ingredients_mode_checkbox" then
            local player = game.get_player(event.player_index)
            if player then
                local prev_state = global.calculator_raw_ingredients_mode_enabled[player.index]
                if prev_state ~= element.state then
                    global.calculator_raw_ingredients_mode_enabled[player.index] = element.state
                    gui.open_calculator_gui(player)
                end
            end
        end
    end)

    -- Handle dropdown change to update tree mode
    script.on_event(defines.events.on_gui_selection_state_changed, function(event)
        local element = event.element
        if element and element.name == "calculator_tree_mode_dropdown" then
            local player = game.get_player(event.player_index)
            if player then
                local selected_index = element.selected_index
                if global.calculator_tree_mode[player.index] ~= selected_index then
                    global.calculator_tree_mode[player.index] = selected_index
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

    -- Handle item picker changes to store values immediately
    script.on_event(defines.events.on_gui_elem_changed, function(event)
        local element = event.element
        local player = game.get_player(event.player_index)
        if element and element.name == "resource_calculator_item_picker" then
            if element.elem_value then
                global.calculator_last_picked_item[player.index] = element.elem_value
            else
                global.calculator_last_picked_item[player.index] = nil
            end
        end
    end)

    -- Handle number input changes to store last picked amount
    script.on_event(defines.events.on_gui_text_changed, function(event)
        local element = event.element
        local player = game.get_player(event.player_index)
        if element and element.name == "resource_calculator_number_input" then
            local value = tonumber(element.text)
            if value and value > 0 then
                global.calculator_last_picked_production_rate[player.index] = value
            else
                global.calculator_last_picked_production_rate[player.index] = 1
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
                        -- Remove previous calculator content
                        local content_flow = frame.resource_calculator_content_flow
                        
                        for _, child in pairs(content_flow.children) do
                            child.destroy()
                        end
                        
                        local tree_mode = global.calculator_tree_mode[player.index]
                        local compact_mode = global.calculator_compact_mode_enabled[player.index]
                        local raw_ingredients_mode = global.calculator_raw_ingredients_mode_enabled[player.index]
                        
                        tree.add_recipe_tree(content_flow, recipe_results, sum_ingredients_table, tree_mode, compact_mode, raw_ingredients_mode)
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

    -- Close the GUI when the close event triggered (e.g., Escape)
    script.on_event(defines.events.on_gui_closed, function(event)
        if event.element and event.element.name == "resource_calculator_frame" then
            event.element.destroy()
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