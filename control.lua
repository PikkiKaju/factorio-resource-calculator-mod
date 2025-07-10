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

    -- Removed: button.player_index = player.index
end

-- This function is called when the mod is loaded and the game starts or a save is loaded.
script.on_init(function()
    game.print("Factorio Resource Calculator: Mod initialized!")
    -- Create the GUI button for all existing players
    for _, player in pairs(game.players) do
        create_calculator_button(player)
    end
end)

-- This function is called when a player joins the game.
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    if player then
        player.print({"gui.welcome-message", player.name}) -- Example of using localized string
        create_calculator_button(player)
    end
end)


-- Function to open the calculator GUI window
local function open_calculator_gui(player)
    local gui = player.gui.screen
    local frame_name = "resource_calculator_frame"
    if gui[frame_name] then
        gui[frame_name].destroy() -- Remove existing frame if present
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

    -- Custom titlebar (vanilla style)
    local titlebar = frame.add{
        type = "flow",
        name = "resource_calculator_titlebar",
        direction = "horizontal"
    }
    titlebar.style.horizontally_stretchable = true
    titlebar.style.vertically_stretchable = false
    titlebar.style.vertical_align = "center"
    titlebar.style.height = 30

    -- Title label
    local title_label = titlebar.add{
        type = "label",
        name = "resource_calculator_title",
        caption = {"gui.calculator-frame-title"},
        style = "frame_title",
        ignored_by_interaction = true
    }

    -- Drag handle
    local drag_handle = titlebar.add{
        type = "empty-widget",
        name = "resource_calculator_drag_handle",
        style = "draggable_space_header",
        ignored_by_interaction = false
    }
    drag_handle.style.horizontally_stretchable = true
    drag_handle.style.height = 24

    -- Close button
    local close_btn = titlebar.add{
        type = "sprite-button",
        name = "resource_calculator_close_button",
        sprite = "utility/close",
        style = "frame_action_button",
        tooltip = {"gui.close"}
    }
    close_btn.style.horizontally_stretchable = false
    close_btn.style.height = 24
    close_btn.style.width = 24

    frame.drag_target = drag_handle

    -- Content flow below titlebar
    local content_flow = frame.add{
        type = "flow",
        direction = "vertical"
    }
    content_flow.add{ type = "choose-elem-button", name = "resource_calculator_item_picker", elem_type = "item" }
    content_flow.add{ type = "textfield", name = "resource_calculator_number_input", text = "1", numeric = true, allow_decimal = true, allow_negative = false }
    content_flow.add{ type = "button", name = "resource_calculator_confirm_button", caption = {"gui.calculator-confirm-button"} }
end

-- Handle the click event for the calculator button
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if element and element.name == "resource_calculator_button" then
        local player = game.get_player(event.player_index)
        if player then
            open_calculator_gui(player)
        end
    elseif element and element.name == "resource_calculator_confirm_button" then
        local player = game.get_player(event.player_index)
        if player then
            -- Find the frame in gui.screen
            local frame = player.gui.screen.resource_calculator_frame
            if frame then
                local item_picker = frame.resource_calculator_item_picker or frame.children[2].resource_calculator_item_picker
                local number_input = frame.resource_calculator_number_input or frame.children[2].resource_calculator_number_input
                local item = item_picker and item_picker.elem_value or nil
                local amount = number_input and tonumber(number_input.text) or 1
                if item and amount then
                    player.print("You selected: " .. item .. " x " .. amount)
                    -- Here you would call your calculation logic
                else
                    player.print("Please select an item and enter a valid number.")
                end
            end
        end
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

local function get_all_recipes()
    local recipes = {}
    for name, recipe_prototype in pairs(data.raw.recipe) do
        -- Filter out hidden or non-craftable recipes if necessary
        if not recipe_prototype.hidden and not recipe_prototype.hidden_from_player_crafting then
            recipes[name] = recipe_prototype
        end
    end
    return recipes
end

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