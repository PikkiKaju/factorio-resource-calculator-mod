local gui = require("scripts.gui")
local calculator = require("scripts.calculator")
local tree = require("scripts.tree")
local util = require("scripts.util")

local M = {}

function M.register()    
    script.on_event(defines.events.on_player_joined_game, function(event)
        local player = game.get_player(event.player_index)
        if player then
            gui.create_calculator_button(player)
            util.init_globals_for_player(player)
        end
    end)

    -- Handle checkbox state change
    script.on_event(defines.events.on_gui_checked_state_changed, function(event)
        local element = event.element
        if element and element.name == "exclude_undiscovered_recipes" then
            local player = game.get_player(event.player_index)
            if player then
                local prev_state = storage.calculator_recipies_filter_enabled[player.index]
                if prev_state ~= element.state then
                    storage.calculator_recipies_filter_enabled[player.index] = element.state
                    gui.open_calculator_gui(player)
                end
            end
        elseif element and element.name == "compact_mode_checkbox" then
            local player = game.get_player(event.player_index)
            if player then
                local prev_state = storage.calculator_compact_mode_enabled[player.index]
                if prev_state ~= element.state then
                    storage.calculator_compact_mode_enabled[player.index] = element.state
                    gui.open_calculator_gui(player)
                end
            end
        elseif element and element.name == "raw_ingredients_mode_checkbox" then
            local player = game.get_player(event.player_index)
            if player then
                local prev_state = storage.calculator_raw_ingredients_mode_enabled[player.index]
                if prev_state ~= element.state then
                    storage.calculator_raw_ingredients_mode_enabled[player.index] = element.state
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
                if storage.calculator_tree_mode[player.index] ~= selected_index then
                    storage.calculator_tree_mode[player.index] = selected_index
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
                storage.calculator_last_picked_item[player.index] = element.elem_value
            else
                storage.calculator_last_picked_item[player.index] = nil
            end
        elseif element and element.name == "resource_calculator_assembler_picker" then
            if element.elem_value then
                local found_prototype = util.find_prototype_by_name(element.elem_value)
                if found_prototype then
                    storage.calculator_last_picked_assembler[player.index] = element.elem_value
                end
            else
                storage.calculator_last_picked_assembler[player.index] = nil -- Default speed if no assembler is selected
            end
        elseif element and element.name == "resource_calculator_furnace_picker" then
            if element.elem_value then
                local found_prototype = util.find_prototype_by_name(element.elem_value)
                if found_prototype then
                    storage.calculator_last_picked_furnace[player.index] = element.elem_value
                end
            else
                storage.calculator_last_picked_furnace[player.index] = nil -- Default speed if no furnace is selected
            end
        elseif element and element.name == "resource_calculator_drill_picker" then
            if element.elem_value then
                local found_prototype = util.find_prototype_by_name(element.elem_value)
                if found_prototype then
                    storage.calculator_last_picked_drill[player.index] = element.elem_value
                    -- storage.calculator_last_picked_drill[player.index] = found_prototype.place_result.mining_speed 
                end
            else
                storage.calculator_last_picked_drill[player.index] = nil -- Default speed if no drill is selected
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
                storage.calculator_last_picked_production_rate[player.index] = value
            else
                storage.calculator_last_picked_production_rate[player.index] = 1
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
                    local item = storage.calculator_last_picked_item[player.index]
                    local amount = storage.calculator_last_picked_production_rate[player.index]
                    
                    if prototypes == nil then
                        player.print("'prototypes' object not available.")
                        return
                    end
                    
                    local assembler_speed = 0.5 -- Default speed if no assembler is selected
                    local furnace_speed = 1 -- Default speed if no furnace is selected
                    local drill_speed = 0.25 -- Default speed if no drill is selected
                    if storage.calculator_last_picked_assembler[player.index] then
                        assembler_speed = util.find_prototype_by_name(storage.calculator_last_picked_assembler[player.index]).place_result.get_crafting_speed()
                    end
                    if storage.calculator_last_picked_furnace[player.index] then
                        furnace_speed = util.find_prototype_by_name(storage.calculator_last_picked_furnace[player.index]).place_result.get_crafting_speed()
                    end
                    if storage.calculator_last_picked_drill[player.index] then
                        drill_speed = util.find_prototype_by_name(storage.calculator_last_picked_drill[player.index]).place_result.mining_speed
                    end
                
                    if item ~= nil and amount ~= nil then
                        local recipe_results = calculator.calculate_requirements(item, amount, assembler_speed, furnace_speed, drill_speed)
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
                        
                        local tree_mode = storage.calculator_tree_mode[player.index]
                        local compact_mode = storage.calculator_compact_mode_enabled[player.index]
                        local raw_ingredients_mode = storage.calculator_raw_ingredients_mode_enabled[player.index]

                        -- save the calculation information to the storage
                        storage.calculator_last_calculated_info[player.index] = {
                            recipe_results = recipe_results,
                            sum_ingredients_table = sum_ingredients_table,
                        }

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
            local player = game.get_player(event.player_index)
            event.element.destroy()
        end
    end)

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