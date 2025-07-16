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

    local button = gui.add{
        type = "button",
        name = button_name,
        caption = {"gui.open-calculator-button"}, 
        tooltip = {"gui.open-calculator-button-tooltip"}
    }

    button.style.minimal_width = 170
    button.style.maximal_width = 170
    button.style.minimal_height = 35
    button.style.maximal_height = 35
end


-- Add a draggable titlebar to the GUI frame
local function add_titlebar(gui)
  local titlebar = gui.add{type = "flow"}
  titlebar.drag_target = gui
  titlebar.add{
    type = "label",
    style = "frame_title",
    caption = {"gui.calculator-frame-title"},
    ignored_by_interaction = true,
  }
  local filler = titlebar.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
  }
  filler.style.height = style.calculator_window_titlebar_dimensions.height
  filler.style.horizontally_stretchable = true
  titlebar.add{
    type = "sprite-button",
    name = "resource_calculator_close_button",
    style = "frame_action_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = {"gui.close-instruction"},
  }
end


-- Add a form flow with item picker, number input and additional options
local function add_form_flow(parent, player)
    local form_flow = parent.add{
        type = "flow",
        direction = "vertical"
    }
    form_flow.style.maximal_height = style.calculator_window_content_dimensions.height
    form_flow.style.minimal_height = style.calculator_window_content_dimensions.height
    form_flow.style.maximal_width = style.calculator_window_content_dimensions.width
    form_flow.style.minimal_width = style.calculator_window_content_dimensions.width
    form_flow.style.margin = style.calculator_window_content_dimensions.margin
    form_flow.style.vertical_spacing = 12
    
    -- Add a label for the item picker
    form_flow.add{
        type = "label",
        caption = {"gui.calculator-item-picker-label"},
        style = "caption_label"
    }

    -- Add horizontal flow for item picker and number input
    local item_picker_flow = form_flow.add{
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
                    table.insert(filters, {filter = "name", name = result.name})
                end
            end
        end
    end

    -- Add an item picker
    local item_picker = item_picker_flow.add{ 
        type = "choose-elem-button", 
        name = "resource_calculator_item_picker", 
        caption = {"gui.calculator-item-picker-placeholder"},
        elem_type = "item",
        elem_filters = filters
    }
    -- 
    if storage.calculator_last_picked_item and storage.calculator_last_picked_item[player.index] then
        item_picker.elem_value = storage.calculator_last_picked_item[player.index]
    end

    -- Add a number input
    local number_input_text = tostring(storage.calculator_last_picked_production_rate[player.index])
    local number_input = item_picker_flow.add{ 
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
    local item_picker_label = item_picker_flow.add{ 
        type = "label", 
        caption = "/s",
        style = "caption_label" 
    }
    item_picker_label.style.right_margin = 20

    -- Add a checkbox for excluding undiscovered recipes
    item_picker_flow.add{
        type = "checkbox",
        name = "exclude_undiscovered_recipes",
        caption = {"gui.calculator-exclude-undiscovered-recipes-checkbox-label"},
        state = storage.calculator_recipies_filter_enabled[player.index]
    }

    -- Add a label for additional options
    form_flow.add{
        type = "label",
        caption = {"gui.calculator-aditional-options-label"},
        style = "caption_label"
    }   
    local additional_options_flow = form_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "form_checkboxes"
    }
    additional_options_flow.style.horizontal_spacing = 20 
    additional_options_flow.style.vertical_align = "center" 
    
    -- Add a dropdown for tree mode selection
    local dropdown_items = {
        {"gui.calculator-calculator-dropdown-tree-mode-text"},
        {"gui.calculator-calculator-dropdown-tree-mode-graphical"}
    }
    local tree_mode_dropdown = additional_options_flow.add{
        type = "drop-down",
        name = "calculator_tree_mode_dropdown",
        caption = {"gui.calculator-text-or-graphical-mode-checkbox-label"},
        items = dropdown_items,
        selected_index = storage.calculator_tree_mode[player.index]
    }
    tree_mode_dropdown.style.minimal_width = 200
    tree_mode_dropdown.style.maximal_width = 200

    -- Add a checkbox for compact mode
    additional_options_flow.add{
        type = "checkbox",
        name = "compact_mode_checkbox",
        caption = {"gui.calculator-compact-mode-label"},
        state = storage.calculator_compact_mode_enabled[player.index]
    }
    -- Add a checkbox to enable raw ingredients display
    additional_options_flow.add{
        type = "checkbox",
        name = "raw_ingredients_mode_checkbox",
        caption = {"gui.calculator-raw-ingredients-mode-label"},
        state = storage.calculator_raw_ingredients_mode_enabled[player.index]
    }

    -- Add a confirm button
    form_flow.add{ 
        type = "button", 
        name = "resource_calculator_confirm_button", 
        caption = {"gui.calculator-confirm-button"} 
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
    frame.style.padding = style.calculator_window_dimensions.padding
    frame.auto_center = true

    -- Add a titlebar to the frame
    add_titlebar(frame)

    -- Add a form with item picker and number input
    add_form_flow(frame, player)
    
    -- Add a scrollable tree for displaying recipes
    local content_flow = frame.add{
        type = "flow",
        name = "resource_calculator_content_flow",
        direction = "vertical"
    }

    -- Make Escape close the window
    player.opened = frame
end

return M