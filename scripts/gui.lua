local tree = require("scripts.tree")
local style = require("style")

local M = {}

-- Create the calculator button in the top-right GUI
function M.create_calculator_button(player)
    local gui = player.gui.top
    local button_name = "resource_calculator_button"

    -- Remove existing button if it somehow persists
    if gui[button_name] then
        gui[button_name].destroy()
    end

    local button = gui.add {
        type = "button",
        name = button_name,
        caption = { "gui.open-calculator-button" },
        tooltip = { "gui.open-calculator-button-tooltip" }
    }

    button.style.minimal_width = 170
    button.style.maximal_width = 170
    button.style.minimal_height = 35
    button.style.maximal_height = 35
end


-- Add a draggable titlebar to the GUI frame
local function add_titlebar(gui, player)
    local titlebar = gui.add { type = "flow" }
    titlebar.drag_target = gui
    titlebar.style.horizontal_spacing = 6
    titlebar.add {
        type = "label",
        style = "frame_title",
        caption = { "gui.calculator-frame-title" },
        ignored_by_interaction = true,
    }
    local filler = titlebar.add {
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true,
    }
    filler.style.height = style.calculator_window_titlebar_dimensions.height
    filler.style.horizontally_stretchable = true
    
    -- Add size mode button
    local current = storage.calculator_window_size_mode[player.index] or "small"
    local b = titlebar.add {
        type = "sprite-button",
        name = "resource_calculator_mode_full",
        -- caption = "Fullscreen",
        style = "frame_action_button",
        sprite = "switch_fullscreen_mode_icon",
        hovered_sprite = "switch_fullscreen_mode_icon",
        clicked_sprite = "switch_fullscreen_mode_icon",
        tooltip = { "gui.calculator-fullscreen-button-tooltip" },
    }
    if current == "full" then b.style = "green_button" end

    titlebar.add {
        type = "sprite-button",
        name = "resource_calculator_close_button",
        style = "frame_action_button",
        sprite = "close_calculator_icon",
        hovered_sprite = "close_calculator_icon",
        clicked_sprite = "close_calculator_icon",
        tooltip = { "gui.close-instruction" },
    }
end


-- Add a form flow with item picker, number input and additional options
local function add_form_flow(parent, player, content_width)
    local form_flow = parent.add {
        type = "flow",
        direction = "vertical"
    }
    form_flow.style.maximal_height = style.calculator_window_content_dimensions.height
    form_flow.style.minimal_height = style.calculator_window_content_dimensions.height
    form_flow.style.maximal_width = content_width
    form_flow.style.minimal_width = content_width
    form_flow.style.margin = style.calculator_window_content_dimensions.margin
    form_flow.style.vertical_spacing = 12

    -- Add flow for pickers
    local pickers_flow = form_flow.add {
        type = "flow",
        direction = "horizontal",
        name = "resource_calculator_picker_flow"
    }
    pickers_flow.style.horizontal_spacing = 30

    -- Add flow item picker and label
    local item_picker_container = pickers_flow.add {
        type = "flow",
        direction = "vertical",
        name = "resource_calculator_item_picker_flow"
    }

    -- Add a label for the item picker
    item_picker_container.add {
        type = "label",
        caption = { "gui.calculator-item-picker-label" },
        style = "caption_label"
    }

    -- Add horizontal flow for item picker and number input
    local item_picker_flow = item_picker_container.add {
        type = "flow",
        direction = "horizontal",
        style = "horizontal_flow",
    }
    item_picker_flow.style.horizontal_spacing = 8
    item_picker_flow.style.vertical_align = "center"

    -- Create a filter for the item picker
    local filters = {}

    if storage.calculator_recipies_filter_enabled[player.index] then
        for name, recipe in pairs(player.force.recipes) do
            if recipe.enabled then
                local result = recipe.products[1]
                if result and result.type == "item" then
                    table.insert(filters, { filter = "name", name = result.name })
                end
            end
        end
    end

    -- Add an item picker
    local item_picker = item_picker_flow.add {
        type = "choose-elem-button",
        name = "resource_calculator_item_picker",
        caption = { "gui.calculator-item-picker-placeholder" },
        elem_type = "item",
        elem_filters = filters
    }
    -- Set the item picker to the last picked item if available
    if storage.calculator_last_picked_item and storage.calculator_last_picked_item[player.index] then
        item_picker.elem_value = storage.calculator_last_picked_item[player.index]
    end

    -- Add a number input
    local number_input_text = tostring(storage.calculator_last_picked_production_rate[player.index])
    local number_input = item_picker_flow.add {
        type = "textfield",
        name = "resource_calculator_number_input",
        text = number_input_text,
        numeric = true,
        allow_decimal = true,
        allow_negative = false,
    }
    number_input.style.minimal_width = 40
    number_input.style.maximal_width = 40

    -- Add a label for the number input
    local item_picker_label = item_picker_flow.add {
        type = "label",
        caption = "/s",
        style = "caption_label"
    }
    item_picker_label.style.right_margin = 20

    -- Add a checkbox for excluding undiscovered recipes
    item_picker_flow.add {
        type = "checkbox",
        name = "exclude_undiscovered_recipes",
        caption = { "gui.calculator-exclude-undiscovered-recipes-checkbox-label" },
        state = storage.calculator_recipies_filter_enabled[player.index]
    }

    -- Flow for machine pickers
    local machine_pickers_flow = pickers_flow.add {
        type = "flow",
        direction = "vertical"
    }

    -- Add a label for the machine pickers
    machine_pickers_flow.add {
        type = "label",
        caption = { "gui.calculator-machine-pickers-label" },
        style = "caption_label"
    }
    -- Add machine pickers flow
    local machine_pickers_flow = machine_pickers_flow.add {
        type = "flow",
        style = "horizontal_flow",
        direction = "horizontal",
    }
    machine_pickers_flow.style.horizontal_spacing = 8
    machine_pickers_flow.style.vertical_align = "center"

    -- Add a label for the assembler picker
    machine_pickers_flow.add {
        type = "label",
        caption = { "gui.calculator-assembler-picker-label" },
        style = "label"
    }
    -- Add an assembler picker
    local assembler_picker = machine_pickers_flow.add {
        type = "choose-elem-button",
        name = "resource_calculator_assembler_picker",
        caption = { "gui.calculator-assembler-picker-placeholder" },
        elem_type = "item",
        elem_filters = {
            { filter = "name", name = "assembling-machine-1" },
            { filter = "name", name = "assembling-machine-2" },
            { filter = "name", name = "assembling-machine-3" }
        }
    }
    -- Set the assembler picker to the last picked item if available
    if storage.calculator_last_picked_assembler and storage.calculator_last_picked_assembler[player.index] then
        assembler_picker.elem_value = storage.calculator_last_picked_assembler[player.index]
    end
    -- Add a label for the furnace picker
    machine_pickers_flow.add {
        type = "label",
        caption = { "gui.calculator-furnace-picker-label" },
        style = "label"
    }
    -- Add an furnace picker
    local furnace_picker = machine_pickers_flow.add {
        type = "choose-elem-button",
        name = "resource_calculator_furnace_picker",
        caption = { "gui.calculator-furnace-picker-placeholder" },
        elem_type = "entity",
        elem_filters = { { filter = "type", type = "furnace" } }
    }
    -- Set the furnace picker to the last picked item if available
    if storage.calculator_last_picked_furnace and storage.calculator_last_picked_furnace[player.index] then
        furnace_picker.elem_value = storage.calculator_last_picked_furnace[player.index]
    end
    -- Add a label for the drill picker
    machine_pickers_flow.add {
        type = "label",
        caption = { "gui.calculator-drill-picker-label" },
        style = "label"
    }
    -- Add a drill picker
    local drill_picker = machine_pickers_flow.add {
        type = "choose-elem-button",
        name = "resource_calculator_drill_picker",
        caption = { "gui.calculator-drill-picker-placeholder" },
        elem_type = "item",
        elem_filters = {
            { filter = "name", name = "burner-mining-drill" },
            { filter = "name", name = "electric-mining-drill" }
        }
    }
    -- Set the drill picker to the last picked item if available
    if storage.calculator_last_picked_drill and storage.calculator_last_picked_drill[player.index] then
        drill_picker.elem_value = storage.calculator_last_picked_drill[player.index]
    end

    -- Add a label for additional options
    form_flow.add {
        type = "label",
        caption = { "gui.calculator-aditional-options-label" },
        style = "caption_label"
    }
    local additional_options_flow = form_flow.add {
        type = "flow",
        direction = "horizontal",
        name = "form_checkboxes"
    }
    additional_options_flow.style.horizontal_spacing = 20
    additional_options_flow.style.vertical_align = "center"

    -- Add a dropdown for tree mode selection
    local dropdown_items = {
        { "gui.calculator-calculator-dropdown-tree-mode-text" },
        { "gui.calculator-calculator-dropdown-tree-mode-graphical" }
    }
    local tree_mode_dropdown = additional_options_flow.add {
        type = "drop-down",
        name = "calculator_tree_mode_dropdown",
        caption = { "gui.calculator-text-or-graphical-mode-checkbox-label" },
        items = dropdown_items,
        selected_index = storage.calculator_tree_mode[player.index]
    }
    tree_mode_dropdown.style.minimal_width = 200
    tree_mode_dropdown.style.maximal_width = 200

    -- Add a checkbox for compact mode
    additional_options_flow.add {
        type = "checkbox",
        name = "compact_mode_checkbox",
        caption = { "gui.calculator-compact-mode-label" },
        state = storage.calculator_compact_mode_enabled[player.index]
    }
    -- Add a checkbox to enable raw ingredients display
    additional_options_flow.add {
        type = "checkbox",
        name = "raw_ingredients_mode_checkbox",
        caption = { "gui.calculator-raw-ingredients-mode-label" },
        state = storage.calculator_raw_ingredients_mode_enabled[player.index]
    }

    -- Add a confirm button
    form_flow.add {
        type = "button",
        name = "resource_calculator_confirm_button",
        caption = { "gui.calculator-confirm-button" }
    }
end


-- Open the calculator GUI window
function M.open_calculator_gui(player)
    local gui = player.gui.screen
    local frame_name = "resource_calculator_frame"
    if gui[frame_name] then
        gui[frame_name].destroy() -- Remove existing frame if present
    end

    -- Ensure the global filter variable exists
    if storage.calculator_recipies_filter_enabled[player.index] == nil then
        storage.calculator_recipies_filter_enabled[player.index] = true
    end

    -- Ensure the tree mode variable exists
    if storage.calculator_tree_mode[player.index] == nil then
        storage.calculator_tree_mode[player.index] = 1
    end

    -- Compute dynamic sizes
    local padding = style.calculator_window_dimensions.padding
    local titlebar_h = style.calculator_window_titlebar_dimensions.height
    local content_h = style.calculator_window_content_dimensions.height
    local window_w = storage.calculator_window_width[player.index] or style.calculator_window_dimensions.width
    local tree_h = storage.calculator_tree_height[player.index] or style.calculator_window_tree_dimensions.height

    -- Apply size mode: manual (default), twothirds, full
    local mode = storage.calculator_window_size_mode[player.index] or "small"
    local res = player.display_resolution
    local scale = player.display_scale or 1
    local screen_w = math.floor(res.width / scale)
    local screen_h = math.floor(res.height / scale)
    if mode == "small" then
        window_w = math.floor(screen_w * 2 / 3)
        local target_frame_h = math.floor(screen_h * 3 / 4)
        tree_h = target_frame_h - (content_h + titlebar_h + 2 * padding + 40)
    elseif mode == "full" then
        window_w = math.max(400, screen_w)
        local target_frame_h = math.max(300, screen_h)
        tree_h = target_frame_h - (content_h + titlebar_h + 2 * padding + 40)
    end
    if tree_h < 200 then tree_h = 200 end
        
    local content_w = window_w - 2 * padding
    local frame_h = content_h + tree_h + titlebar_h + 2 * padding + 40

    -- Create a new frame for the calculator GUI
    local frame = gui.add {
        type = "frame",
        name = frame_name,
        direction = "vertical"
    }
    frame.style.minimal_width = window_w
    frame.style.maximal_width = window_w
    frame.style.minimal_height = frame_h
    frame.style.maximal_height = frame_h
    frame.style.padding = style.calculator_window_dimensions.padding
    frame.auto_center = true

    -- Add a titlebar to the frame
    add_titlebar(frame, player)

    -- Add a form with item picker and number input sized to content width
    add_form_flow(frame, player, content_w)

    -- Add a scrollable tree for displaying recipes
    local content_flow = frame.add {
        type = "flow",
        name = "resource_calculator_content_flow",
        direction = "vertical"
    }

    -- Add the recipe tree to the content flow if it was previously calculated
    if storage.calculator_last_calculated_info[player.index] then
        -- Temporarily override tree dimensions in style for this build
        local orig_w = style.calculator_window_tree_dimensions.width
        local orig_h = style.calculator_window_tree_dimensions.height
        style.calculator_window_tree_dimensions.width = content_w
        style.calculator_window_tree_dimensions.height = tree_h

        tree.add_recipe_tree(
            content_flow,
            storage.calculator_last_calculated_info[player.index].recipe_results,
            storage.calculator_last_calculated_info[player.index].sum_ingredients_table,
            storage.calculator_tree_mode[player.index],
            storage.calculator_compact_mode_enabled[player.index],
            storage.calculator_raw_ingredients_mode_enabled[player.index]
        )

        -- Restore original values to avoid affecting other UIs
        style.calculator_window_tree_dimensions.width = orig_w
        style.calculator_window_tree_dimensions.height = orig_h
    end

    -- Make Escape close the window
    player.opened = frame
end

return M
