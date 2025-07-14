-- Recursively add a graphical tree of recipe results to the GUI
local function add_recipe_tree_to_gui(parent, recipe_table, indent_level, is_last)
    indent_level = indent_level or 0
    is_last = is_last or false
    local flow = parent.add{
        type = "flow",
        direction = "horizontal"
    }
    -- Indent visually using labels to mimic tree branches
    local branch = ""
    for i = 1, indent_level do
        branch = branch .. (i == indent_level and (is_last and "└" or "├") or "│") .. "   "
    end
    if branch ~= "" then
        flow.add{
            type = "label",
            caption = branch,
            style = "caption_label"
        }
    end
    -- Show main item info, replace '-' with ' '
    local item_name = recipe_table.name and string.gsub(recipe_table.name, "-", " ") or "?"
    local label_text = item_name
    if recipe_table.item_amount_per_second then
        label_text = label_text .. " (" .. tostring(recipe_table.item_amount_per_second) .. "/s)"
    end
    flow.add{
        type = "label",
        caption = label_text,
        style = "caption_label"
    }
    -- Show machine count if present
    if recipe_table.machines_amount then
        flow.add{
            type = "label",
            caption = " | Machines: " .. string.format("%.2f", recipe_table.machines_amount),
            style = "caption_label"
        }
    end
    -- Recursively add ingredients as branches
    if recipe_table.ingredients and #recipe_table.ingredients > 0 then
        for i, ingredient in ipairs(recipe_table.ingredients) do
            add_recipe_tree_to_gui(parent, ingredient, indent_level + 1, i == #recipe_table.ingredients)
        end
    end
end
-- Custom serialization function for recipe tables
local function serialize_recipe_table(tbl, indent)
    indent = indent or ""
    local lines = {}
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    -- Print 'name' key first if present
    if tbl.name then
        table.insert(lines, indent .. "name: " .. tostring(tbl.name))
    end
    -- Print other keys except 'ingredients' and 'name'
    for k, v in pairs(tbl) do
        if k ~= "name" and k ~= "ingredients" then
            table.insert(lines, indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
    -- Print ingredients recursively
    if tbl.ingredients and type(tbl.ingredients) == "table" and #tbl.ingredients > 0 then
        table.insert(lines, indent .. "ingredients:")
        for _, ingredient in ipairs(tbl.ingredients) do
            table.insert(lines, serialize_recipe_table(ingredient, indent .. "  "))
        end
    end
    return table.concat(lines, "\n")
end

-- Function to create the calculator button in the top-right GUI
local function create_calculator_button(player)
    local gui = player.gui.top
    local button_name = "resource_calculator_button"

    -- Remove existing button if it somehow persists (e.g., on mod reload)
    if gui[button_name] then
        gui[button_name].destroy()
    end

    local button = gui.add{
        type = "button",
        name = button_name,
        caption = {"gui.open-calculator-button"}, -- Use localized caption
        tooltip = {"gui.open-calculator-button-tooltip"} -- Optional tooltip
    }

    button.style.minimal_width = 170
    button.style.maximal_width = 170
    button.style.minimal_height = 35
    button.style.maximal_height = 35
end

-- This function is called when the mod is loaded and the game starts or a save is loaded.
script.on_init(function()   
    if not global then global = {} end
    global.calculator_recipies_filter_enabled = {}
    -- Create the GUI button for all existing players
    for _, player in pairs(game.players) do
        create_calculator_button(player)
    end
end)

-- This function is called when a player joins the game.
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    if player then
        create_calculator_button(player)
        global.calculator_recipies_filter_enabled[player.index] = true
    end
end)

-- Function to add a draggable titlebar to the GUI frame
function add_titlebar(gui, caption, close_button_name)
  local titlebar = gui.add{type = "flow"}
  titlebar.drag_target = gui
  titlebar.add{
    type = "label",
    style = "frame_title",
    caption = caption,
    ignored_by_interaction = true,
  }
  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
  }
  filler.style.height = 24
  filler.style.horizontally_stretchable = true
  titlebar.add{
    type = "sprite-button",
    name = close_button_name,
    style = "frame_action_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = {"gui.close-instruction"},
  }
end

local style = {}
style.calculator_window_dimensions = {
    width = 800,
    height = 600
}
style.calculator_window_tree_dimensions = {
    width = style.calculator_window_dimensions.width - 30,
    height = style.calculator_window_dimensions.height - 200
}

-- Function to open the calculator GUI window
local function open_calculator_gui(player)
    local gui = player.gui.screen
    local frame_name = "resource_calculator_frame"
    if gui[frame_name] then
        gui[frame_name].destroy() -- Remove existing frame if present
    end

    -- Ensure the global filter variable exists
    if global.calculator_recipies_filter_enabled[player.index] == nil then
        global.calculator_recipies_filter_enabled[player.index] = true
    end

    -- Create a new frame for the calculator GUI
    local frame = gui.add{
        type = "frame",
        name = frame_name,
        direction = "vertical"
    }
    frame.style.minimal_width = style.calculator_window_dimensions.width
    frame.style.maximal_width = style.calculator_window_dimensions.width
    frame.style.minimal_height = style.calculator_window_dimensions.height
    frame.style.maximal_height = style.calculator_window_dimensions.height
    frame.auto_center = true

    -- Add a titlebar to the frame
    add_titlebar(frame, {"gui.calculator-frame-title"}, "resource_calculator_close_button")

    -- Content flow below titlebar
    local content_flow = frame.add{
        type = "flow",
        direction = "vertical"
    }
    content_flow.style.vertical_spacing = 12
    content_flow.style.maximal_height = 420
    content_flow.style.minimal_height = 420
    
    -- Add a label for the item picker
    content_flow.add{
        type = "label",
        caption = {"gui.calculator-item-picker-label"},
        style = "caption_label"
    }

    -- Add horizontal flow for item picker and number input
    local item_picker_flow = content_flow.add{
        type = "flow",
        direction = "horizontal",
        style = "horizontal_flow",
    }
    item_picker_flow.style.horizontal_spacing = 8 -- Adjust spacing between elements
    item_picker_flow.style.vertical_align = "center" -- Center vertically within the flow

    -- Create a filter for the item picker
    local filters = {}
    
    if global.calculator_recipies_filter_enabled[player.index] then
        for name, recipe in pairs(player.force.recipes) do
            if recipe.enabled then
                local result = recipe.products[1]
                if result and result.type == "item" then
                    table.insert(filters, {filter = "name", name = result.name})
                end
            end
        end
    end

    -- Add an item picker
    item_picker_flow.add{ 
        type = "choose-elem-button", 
        name = "resource_calculator_item_picker", 
        caption = {"gui.calculator-item-picker-placeholder"},
        elem_type = "item",
        elem_filters = filters
    }
    -- Add a number input
    local number_input = item_picker_flow.add{ 
        type = "textfield", 
        name = "resource_calculator_number_input", 
        text = "1", 
        numeric = true, 
        allow_decimal = true, 
        allow_negative = false,
    }
    number_input.style.minimal_width = 40
    number_input.style.maximal_width = 40
    -- Add a label for the number input
    item_picker_flow.add{ 
        type = "label", 
        caption = "/s",
        style = "caption_label" 
    }
    -- Add a checkbox for additional options (optional)
    content_flow.add{
        type = "checkbox",
        name = "exclude_undiscovered_recipes",
        caption = {"gui.calculator-exclude-undiscovered-recipes-checkbox-label"},
        state = global.calculator_recipies_filter_enabled[player.index]
    }
    -- Add a confirm button
    content_flow.add{ 
        type = "button", 
        name = "resource_calculator_confirm_button", 
        caption = {"gui.calculator-confirm-button"} 
    }
end

-- Handle checkbox state change to update filters_enabled per player
script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    local element = event.element
    if element and element.name == "exclude_undiscovered_recipes" then
        local player = game.get_player(event.player_index)
        if player then
            local prev_state = global.calculator_recipies_filter_enabled[player.index]
            if prev_state ~= element.state then
                global.calculator_recipies_filter_enabled[player.index] = element.state
                open_calculator_gui(player)
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
            open_calculator_gui(player)
        end
    end
end)

-- Function to calculate resource requirements for a given item and production rate
local function calculate_requirements(target_item_name, target_production_rate, machine_speed)
    local recipe = prototypes.recipe[target_item_name]
    local recipe_table = {}
    local ingredients_table = {}
    local player = game.players[1] 

    if recipe == nil then
        local item = prototypes.item[target_item_name]
        local final_item_table = {
            name = item.name,
            item_amount_per_second = target_production_rate
        }
        return final_item_table
    end

    local default_production_rate_per_second = recipe.main_product.amount / recipe.energy
    local process_amount = target_production_rate / recipe.main_product.amount
    local total_time = process_amount * recipe.energy 
    local machines_amount = total_time * machine_speed
    local adjusted_production_rate = target_production_rate / default_production_rate_per_second

    for _, ingredient in pairs(recipe.ingredients) do
        table.insert(ingredients_table, calculate_requirements(
            ingredient.name, 
            ingredient.amount * process_amount,
            machine_speed
        ))
    end
    recipe_table = {
        name = target_item_name,
        item_amount_per_second = target_production_rate,
        process_amount_per_second = process_amount,
        machines_amount = machines_amount,
        energy = recipe.energy,
        ingredients = ingredients_table
    }

    return recipe_table
    -- This is where the core calculation logic goes.
    -- It would involve:
    -- 3. Summing up raw resource requirements.
    -- 4. Calculating machine counts based on crafting speed of assemblers and recipe crafting time.
    -- This is a complex algorithm (often using graph traversal or a bill-of-materials approach).
end

function sum_requirements(recipe_results, sum_ingredients_table)
    local name = recipe_results.name
    local amount = recipe_results.item_amount_per_second
    game.players[1].print("Summing up: " .. name .. " at " .. tostring(amount) .. " / second")
    if sum_ingredients_table[name] == nil then
        sum_ingredients_table[name] = amount
    else
        local existing = sum_ingredients_table[name]
        existing = existing + amount
    end
    if not recipe_results.ingredients then
        return
    end
    
    -- recursively traverse the recipe results and sum up the ingredients
    for _, ingredient in pairs(recipe_results.ingredients) do
        sum_requirements(ingredient, sum_ingredients_table)
    end
end

-- Handle the click event for the calculator button
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    -- If the clicked element is the calculator button, open the GUI
    if element and element.name == "resource_calculator_button" then
        local player = game.get_player(event.player_index)
        if player then
            open_calculator_gui(player)
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
                    local recipe_results = calculate_requirements(item, amount, 1)
                    local result_label_name = "resource_calculator_result_label"
                    local sum_result_label_name = "resource_calculator_sum_result_label"
                    local sum_ingredients_table = {}
                    -- Sum the requirements
                    if recipe_results.ingredients then
                        for _, ingredient in pairs(recipe_results.ingredients) do
                            sum_requirements(ingredient, sum_ingredients_table)
                        end
                    end
                    -- Remove previous result labels/tree if present
                    local content_flow = frame.children[2]
                    
                    for _, child in pairs(content_flow.children) do
                        if child.name == result_label_name or child.name == sum_result_label_name or child.name == "resource_calculator_result_tree" then
                            child.destroy()
                        end
                    end
                    -- Add graphical tree for recipe results
                    local tree_flow = content_flow.add{
                        type = "scroll-pane",
                        name = "resource_calculator_result_tree",
                        direction = "vertical"
                    }
                    tree_flow.style.minimal_height = style.calculator_window_tree_dimensions.height 
                    tree_flow.style.maximal_height = style.calculator_window_tree_dimensions.height
                    tree_flow.style.minimal_width = style.calculator_window_tree_dimensions.width
                    tree_flow.style.maximal_width = style.calculator_window_tree_dimensions.width
                    tree_flow.vertical_scroll_policy = "auto"
                    add_recipe_tree_to_gui(tree_flow, recipe_results, 0, true)
                    -- Add summed requirements as text below
                    tree_flow.add{
                        type = "label",
                        name = sum_result_label_name,
                        caption = serialize_recipe_table(sum_ingredients_table, "  "),
                        style = "caption_label"
                    }
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
