-- Require flib modules
local flib_gui = require("__flib__/gui")
local flib_templates = require("__flib__/gui-templates")

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

-- Register close handler for flib
local function calculator_close_handler(e)
    local player = game.get_player(e.player_index)
    if player then
        local gui = player.gui.screen
        local frame = gui.resource_calculator_frame
        if frame then
            frame.destroy()
        end
    end
end
flib_gui.add_handlers({ calculator_close_handler = calculator_close_handler })

-- Function to open the calculator GUI window (with flib draggable titlebar)
local function open_calculator_gui(player)
    local gui = player.gui.screen
    local frame_name = "resource_calculator_frame"
    if gui[frame_name] then
        gui[frame_name].destroy() -- Remove existing frame if present
    end

    local elems = flib_gui.add(gui.gui.screen, {
        type = "frame",
        name = frame_name,
        direction = "vertical",
        style_mods = {
            minimal_width = 450,
            maximal_width = 450,
            minimal_height = 280,
            maximal_height = 280
        },
        children = {
            
            {
                type = "choose-elem-button",
                name = "resource_calculator_item_picker",
                elem_type = "item"
            },
            {
                type = "textfield",
                name = "resource_calculator_number_input",
                text = "1",
                numeric = true,
                allow_decimal = true,
                allow_negative = false
            },
            {
                type = "button",
                name = "resource_calculator_confirm_button",
                caption = {"gui.calculator-confirm-button"}
            }
        }
    })
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
            local frame = player.gui.screen.resource_calculator_frame
            if frame then
                local item_picker = frame.resource_calculator_item_picker
                local number_input = frame.resource_calculator_number_input
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