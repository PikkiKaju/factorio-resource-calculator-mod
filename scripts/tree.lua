local style = require("style")

local M = {}

-- Recursively add a text tree of recipe results to the GUI
local function add_text_recipe_tree_to_gui(parent, recipe_table, indent_level, is_last, pipes, raw_ingredients_mode)
    indent_level = indent_level or 0
    is_last = is_last or false
    pipes = pipes or {}

    -- Check if the item is a raw ingredient
    if not raw_ingredients_mode and recipe_table.raw_ingredient == true then
        return
    end

    local flow = parent.add{
        type = "flow",
        direction = "horizontal"
    }
    -- Indent visually using labels to mimic tree branches
    local branch = ""
    if indent_level > 0 then
        for i = 1, indent_level do
            if i == indent_level then
                -- Only show ┬ for non-raw ingredients (machines_amount present)
                if recipe_table.ingredients and #recipe_table.ingredients > 0 and recipe_table.ingredients[1].machines_amount ~= nil then
                    branch = branch .. (is_last and "└┬ " or "├┬ ")
                else
                    branch = branch .. (is_last and "└─ " or "├─ ")
                end
            else
                branch = branch .. (pipes[i] and "│ " or "     ")
            end
        end
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
        label_text = label_text .. " (" .. string.format("%.2f", recipe_table.item_amount_per_second) .. "/s)"
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
            local new_pipes = {}
            for k, v in pairs(pipes) do new_pipes[k] = v end
            new_pipes[indent_level + 1] = (i ~= #recipe_table.ingredients)
            add_text_recipe_tree_to_gui(parent, ingredient, indent_level + 1, i == #recipe_table.ingredients, new_pipes, raw_ingredients_mode)
        end
    end
end


-- Add summed requirements as a graphical tree below
function M.add_summed_requirements_to_gui(parent, recipe_results, sum_ingredients_table)
    parent.add{
        type = "line"
    }
    local sum_flow = parent.add{
        type = "flow",
        name = sum_result_label_name,
        direction = "vertical"
    }
    sum_flow.add{
        type = "label",
        caption = "Summarized ingredients:",
        style = "caption_label"
    }

    -- Sort the summed ingredients table by keys and display them
    local sum_keys = {}
    for k, _ in pairs(sum_ingredients_table) do table.insert(sum_keys, k) end
    table.sort(sum_keys)
    for i, k in ipairs(sum_keys) do
        local v = sum_ingredients_table[k]
        local sum_item_flow = sum_flow.add{
            type = "flow",
            direction = "horizontal"
        }
        local branch = (i == #sum_keys and "└─ " or "├─ ")
        sum_item_flow.add{
            type = "label",
            caption = branch,
            style = "caption_label"
        }
        sum_item_flow.add{
            type = "label",
            caption = string.gsub(k, "-", " ") .. ": ",
            style = "caption_label"
        }
        sum_item_flow.add{
            type = "label",
            caption = "" .. string.format("%.2f", v) .. "/s",
            style = "caption_label"
        }
    end
end 


-- Add a tree node to the GUI
local function add_tree_node(parent, node_info, layer, column, is_last, compact_mode)
    layer = layer or 0
    column = column or 0
    local frame_type = is_last and "frame" or "flow"
    -- Add vertical flow for the sprite and label
    local node_flow = parent.add{
        type = frame_type,
        name = "tree_node_flow_" .. layer .. "_" .. column .. "_" .. node_info.name,
        direction = "vertical"
    }
    node_flow.style.vertical_align = "center"
    node_flow.style.horizontal_align = "left"
    node_flow.style.padding = 2
    node_flow.style.vertical_spacing = 1

    -- Add a horizontal flow for the sprite and numbers
    local node_sprite_numbers_flow = node_flow.add{
        type = "flow",
        direction = "horizontal"
    }
    node_sprite_numbers_flow.style.vertical_align = "center"
    node_sprite_numbers_flow.style.horizontal_align = "center"
    node_sprite_numbers_flow.style.horizontal_spacing = 1
    
    -- Add a sprite for the node
    -- Determine the sprite name based on the node type
    local sprite_name
    if node_info.type == "fluid" then
        sprite_name = "fluid/" .. node_info.name  
    elseif node_info.type == "item" then
        sprite_name = "item/" .. node_info.name
    elseif node_info.type == "entity" then
        sprite_name = "entity/" .. node_info.name
    elseif node_info.type == "recipe" then
        sprite_name = "recipe/" .. node_info.name
    elseif node_info.type == "equipment" then
        sprite_name = "equipment/" .. node_info.name
    elseif node_info.type == "virtual-signal" then
        sprite_name = "virtual-signal/" .. node_info.name
    end
    -- Add the sprite
    node_sprite_numbers_flow.add{
        type = "sprite",
        sprite = sprite_name,
        width = style.tree_node_sprite_dimensions.width,
        height = style.tree_node_sprite_dimensions.height,
        horizontal_align = "center"
    }

    -- Add a vertical flow for the node's numbers
    local numbers_flow = node_sprite_numbers_flow.add{
        type = "flow",
        direction = "vertical",
        vertical_align = "center",
        horizontal_align = "left"
    }

    -- Add the production rate label
    if node_info.item_amount_per_second then
        local rate_label = compact_mode and {"gui-tree.production-rate-label-short"} or {"gui-tree.production-rate-label-long"}
        local rate_value = 0
        if node_info.item_amount_per_second >= 100 then
            rate_value = string.format("%.0f", node_info.item_amount_per_second)
        elseif node_info.item_amount_per_second >= 10 then
            rate_value = string.format("%.1f", node_info.item_amount_per_second)
        else
            rate_value = string.format("%.2f", node_info.item_amount_per_second)
        end

        numbers_flow.add{
            type = "label",
            caption = {"", rate_label, ": ", rate_value},
            style = "caption_label"
        }
    else
        numbers_flow.add{
            type = "label",
            caption = "Amount: N/A",
            style = "caption_label"
        }
    end
    
    -- Add the machines label
    if node_info.machines_amount then
        local machines_label = compact_mode and {"gui-tree.machines-amount-label-short"} or {"gui-tree.machines-amount-label-long"}
        local machines_value = 0
        if node_info.machines_amount >= 100 then
            machines_value = string.format("%.0f", node_info.machines_amount)
        elseif node_info.machines_amount >= 10 then
            machines_value = string.format("%.1f", node_info.machines_amount)
        else
            machines_value = string.format("%.2f", node_info.machines_amount)
        end

        numbers_flow.add{
            type = "label",
            caption = {"", machines_label, ": ", machines_value},
            style = "caption_label"
        }
    end 

    -- Add the item name label
    node_flow.add{
        type = "label",
        caption = string.gsub(node_info.name, "-", " "),
        style = "caption_label",
    }
    
end


-- Add a tree layer to the GUI
local function add_tree_layer(parent, layer, column, node_spacing)
    -- Create a horizontal flow for nodes
    local content_flow = parent.add{
        type = "frame",
        name = "tree_layer_flow_" .. layer .. "_" .. column,
        direction = "vertical",
        horizontal_spacing = node_spacing
    }
    content_flow.style.horizontal_align = "center"
    content_flow.style.vertical_align = "center"
    content_flow.style.padding = 2

    -- Add a flow for the main item 
    local main_item = content_flow.add{
        type = "flow"
    }
    main_item.style.horizontal_align = "center"
    main_item.style.vertical_align = "center"
    main_item.style.horizontally_stretchable = true

    -- Add a flow for the ingredients
    local ingredients = content_flow.add{
        type = "flow",
        direction = "horizontal",
        vertical_align = "center",
        horizontal_align = "center",
        horizontal_spacing = node_spacing
    }
    return {
        content_flow = content_flow,
        main_item = main_item,
        ingredients = ingredients
    } 
end


-- Add a graphical recipe tree to the GUI
local function add_graphicap_recipe_tree_to_gui(parent, recipe_table, layer, column, compact_mode, raw_ingredients_mode)
    layer = layer or 0
    column = column or 0
    local is_last = false

    -- Check if the item is a raw ingredient
    if not raw_ingredients_mode and recipe_table.raw_ingredient == true then
        return
    end

    -- Add a new layer for main item and ingredients
    local layer_flows = add_tree_layer(parent, layer, column, 10)

    -- Add the main item node
    add_tree_node(
        layer_flows.main_item, 
        {
            name = recipe_table.name,
            item_amount_per_second = recipe_table.item_amount_per_second,
            machines_amount = recipe_table.machines_amount,
            type = recipe_table.type or "unknown"
        },
        layer,
        0,
        is_last,
        compact_mode
    )

    -- If there are ingredients, recursively add them to the next layer
    if recipe_table.ingredients and #recipe_table.ingredients > 0 then
        local child_column = column
        for _, ingredient in ipairs(recipe_table.ingredients) do
            add_graphicap_recipe_tree_to_gui(layer_flows.ingredients, ingredient, layer + 1, child_column, compact_mode, raw_ingredients_mode)
            child_column = child_column + 1
        end
    end
end


-- Add tree for recipe results
function M.add_recipe_tree(parent, recipe_results, sum_ingredients_table, tree_mode, compact_mode, raw_ingredients_mode)
    local tree_scroll = parent.add{
        type = "flow",
        name = "resource_calculator_result_flow",
        direction = "vertical",
        vertical_align = "top",
        horizontal_align = "center"
    }
    tree_scroll.style.minimal_height = style.calculator_window_tree_dimensions.height
    tree_scroll.style.maximal_height = style.calculator_window_tree_dimensions.height
    tree_scroll.style.minimal_width = style.calculator_window_tree_dimensions.width
    tree_scroll.style.maximal_width = style.calculator_window_tree_dimensions.width
    tree_scroll.style.margin = style.calculator_window_tree_dimensions.margin   
    
    -- Add a top-level label for clarity
    tree_scroll.add{
        type = "label",
        caption = "Recipe breakdown:",
        style = "caption_label"
    }

    -- Add a scroll pane for the tree and summed ingredients requirements
    local tree_flow = tree_scroll.add{
        type = "scroll-pane",
        name = "resource_calculator_result_tree",
        direction = "vertical"
    }
    tree_flow.style.minimal_height = style.calculator_window_tree_dimensions.height 
    tree_flow.style.maximal_height = style.calculator_window_tree_dimensions.height
    tree_flow.style.minimal_width = style.calculator_window_tree_dimensions.width
    tree_flow.style.maximal_width = style.calculator_window_tree_dimensions.width

    tree_flow.vertical_scroll_policy = "dont-show-but-allow-scrolling"
    tree_flow.horizontal_scroll_policy = "dont-show-but-allow-scrolling"

    if tree_mode == 1 then
        -- Text mode
        add_text_recipe_tree_to_gui(tree_flow, recipe_results, 0, true, {}, raw_ingredients_mode)
    elseif tree_mode == 2 then
        -- Graphical mode
        add_graphicap_recipe_tree_to_gui(tree_flow, recipe_results, 0, 0, compact_mode, raw_ingredients_mode)
    end

    M.add_summed_requirements_to_gui(tree_flow, recipe_results, sum_ingredients_table)

end

return M