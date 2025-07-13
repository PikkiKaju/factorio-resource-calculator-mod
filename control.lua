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

-- Function to get all recipes in the game
local function get_all_recipes(hidden)
    local recipes = {}
    for name, recipe_prototype in pairs(data.raw.recipe) do
        if hidden then
            recipes[name] = recipe_prototype
        else
            if not recipe_prototype.hidden and not recipe_prototype.hidden_from_player_crafting then
                recipes[name] = recipe_prototype
            end
        end
    end
    return recipes
end

-- Function to calculate resource requirements for a given item and production rate
local function calculate_requirements(target_item_name, target_production_rate)
    local all_recipes = get_all_recipes()
    local all_items = data.raw.item -- Access all item prototypes
    local all_fluids = data.raw.fluid -- Access all fluid prototypes
    local all_assemblers = data.raw["assembling-machine"] -- Access all assembling machine prototypes

    -- This is where the core calculation logic goes.
    -- It would involve:
    -- 1. Finding the recipe(s) for the target_item_name.
    -- 2. Recursively traversing the ingredient dependencies for that recipe.
    -- 3. Summing up raw resource requirements.
    -- 4. Calculating machine counts based on crafting speed of assemblers and recipe crafting time.
    -- This is a complex algorithm (often using graph traversal or a bill-of-materials approach).

    game.print("Calculating for: " .. target_item_name .. " at " .. target_production_rate .. " / second")

    -- Example: Just print a few recipe names
    -- for name, recipe in pairs(all_recipes) do
    --     game.print("Recipe: " .. name)
    -- end

    -- Return calculated results (e.g., a table of raw resources and machine counts)
    return {
        raw_materials = {},
        machines = {}
    }
end

-- Example of calling the calculation (e.g., from your GUI handler)
-- local results = calculate_requirements("electronic-circuit", 10)
-- game.print(serpent.block(results)) -- Use serpent.block for pretty printing tables (requires serpent library)