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

-- Function to get all recipes available to the player
local function get_available_recipes(player)
    local recipes = {}
    for name, recipe in pairs(player.force.recipes) do
        if recipe.enabled then
            recipes[name] = recipe
        end
    end
    return recipes
end

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
    frame.style.minimal_width = 450
    frame.style.maximal_width = 450
    frame.style.minimal_height = 280
    frame.style.maximal_height = 280
    frame.auto_center = true

    -- Add a titlebar to the frame
    add_titlebar(frame, {"gui.calculator-frame-title"}, "resource_calculator_close_button")

    -- Content flow below titlebar
    local content_flow = frame.add{
        type = "flow",
        direction = "vertical"
    }
    content_flow.style.vertical_spacing = 12

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
local function calculate_requirements(target_item_name, target_production_rate)
    local recipe = prototypes.recipe[target_item_name]
    local recipe_table = {}
    local ingredients_table = {}
    local player = game.players[1] 


    if recipe == nil then
        local item = prototypes.item[target_item_name]
        local final_item_table = {
            name = item.name,
            amount = target_production_rate
            
        }
        player.print("-------- Item Table --------")
        player.print(serpent.block(final_item_table))
        player.print("-------- End of item Table --------")
        return final_item_table
    end
    target_production_rate = recipe.main_product.amount/target_production_rate
    for _, ingredient in pairs(recipe.ingredients) do
        table.insert(ingredients_table, calculate_requirements(
            ingredient.name, 
            ingredient.amount * target_production_rate, 
            recipes_table
        ))
    end
    recipe_table = {
        name = target_item_name,
        amount = target_production_rate,
        energy = recipe.energy,
        ingredients = ingredients_table
    }
    player.print("-------- Recipe Table --------")
    player.print(serpent.block(recipe_table))
    player.print("-------- End of Recipe Table --------")

    return recipe_table
    -- This is where the core calculation logic goes.
    -- It would involve:
    -- 1. Finding the recipe(s) for the target_item_name.
    -- 2. Recursively traversing the ingredient dependencies for that recipe.
    -- 3. Summing up raw resource requirements.
    -- 4. Calculating machine counts based on crafting speed of assemblers and recipe crafting time.
    -- This is a complex algorithm (often using graph traversal or a bill-of-materials approach).

    -- Example: Just print a few recipe names
    -- for name, recipe in pairs(all_recipes) do
    --     game.print("Recipe: " .. name)
    -- end
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

                player.print("Calculating for: " .. item .. " at " .. amount .. " / second")

                if item ~= nil and amount ~= nil then
                    local recipe_results = calculate_requirements(item, amount)
                    -- Remove previous result label if present
                    local result_label_name = "resource_calculator_result_label"
                    local content_flow = frame.children[2]
                    for _, child in pairs(content_flow.children) do
                        if child.name == result_label_name then
                            child.destroy()
                        end
                    end
                    -- Add new result label
                    content_flow.add{
                        type = "label",
                        name = result_label_name,
                        caption = serialize_recipe_table(recipe_results, "  "),
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
