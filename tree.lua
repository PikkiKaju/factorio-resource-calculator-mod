local style = require("style")

local M = {}

-- Recursively add a text tree of recipe results to the GUI
local function add_text_recipe_tree_to_gui(parent, recipe_table, indent_level, is_last, pipes)
    indent_level = indent_level or 0
    is_last = is_last or false
    pipes = pipes or {}
    local flow = parent.add{
        type = "flow",
        direction = "horizontal"
    }
    -- Indent visually using labels to mimic tree branches
    local branch = ""
    if indent_level > 0 then
        for i = 1, indent_level do
            if i == indent_level then
                if recipe_table.ingredients and #recipe_table.ingredients > 0 then
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
            add_text_recipe_tree_to_gui(parent, ingredient, indent_level + 1, i == #recipe_table.ingredients, new_pipes)
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
local function add_tree_node(parent, node_info)
    local node_flow = parent.add{
        type = "flow",
        name = "tree_node_flow_" .. node_info.name,
        direction = "horizontal",
        vertical_align = "center"
    }
    -- Add the node label
    node_flow.add{
        type = "label",
        caption = node_info.name,
        style = "caption_label"
    }
    -- Add the sprite if available
    local sprite_name = "item/" .. node_info.name
    node_flow.add{
        type = "sprite",
        sprite = sprite_name,
        width = style.tree_node_sprite_dimensions.width,
        height = style.tree_node_sprite_dimensions.height,
    }
    -- Add a vertical flow for the node's numbers
    local numbers_flow = node_flow.add{
        type = "flow",
        direction = "vertical",
        vertical_align = "center"
    }
    -- Add the amount label
    numbers_flow.add{
        type = "label",
        caption = string.format(" (%.2f/s)", node_info.item_amount_per_second),
        style = "caption_label"
    }
    -- Add the machines label
    numbers_flow.add{
        type = "label",
        caption = string.format(" (%.2f/s)", node_info.machines_amount),
        style = "caption_label"
    }
end


-- Recursively add a graphical tree of recipe results to the GUI
local function add_graphicap_recipe_tree_to_gui(parent, recipe_table, indent_level, is_last, pipes)
    is_last = is_last or false
    pipes = pipes or {}

    -- Create a vertical flow for each node
    local content_flow = parent.add{
        type = "flow",
        direction = "vertical",
        vertical_align = "center"
    }

    -- Add top-level node
    local item_flow = content_flow.add{
        type = "flow",
        direction = "horizontal"
    }

    -- Add recipe tree
    add_text_recipe_tree_to_gui(content_flow, recipe_table, indent_level, is_last, pipes)

    -- Indent visually using empty-widget for spacing
    -- if indent_level > 0 then
    --     item_flow.add{
    --         type = "empty-widget",
    --         style = "empty_widget",
    --         -- width per indent level
    --         minimal_width = 24 * indent_level,
    --         maximal_width = 24 * indent_level
    --     }
    -- end

    -- Draw vertical arrow if there are children
    -- if recipe_table.ingredients and #recipe_table.ingredients > 0 then
    --     local arrow_flow = node_flow.add{
    --         type = "flow",
    --         direction = "vertical"
    --     }
    --     arrow_flow.add{
    --         type = "line",
    --         direction = "vertical"
    --     }
        -- Optionally, add a label with a Unicode arrow for clarity
        -- arrow_flow.add{
        --     type = "label",
        --     caption = "↓",
        --     style = "caption_label"
        -- }
    -- end
end


-- Add tree for recipe results
function M.add_recipe_tree(parent, recipe_results, sum_ingredients_table)
    local tree_scroll = parent.add{
        type = "scroll-pane",
        name = "resource_calculator_result_tree",
        direction = "vertical"
    }
    tree_scroll.style.minimal_height = style.calculator_window_tree_dimensions.height 
    tree_scroll.style.maximal_height = style.calculator_window_tree_dimensions.height
    tree_scroll.style.minimal_width = style.calculator_window_tree_dimensions.width
    tree_scroll.style.maximal_width = style.calculator_window_tree_dimensions.width
    tree_scroll.vertical_scroll_policy = "dont-show-but-allow-scrolling"
    tree_scroll.horizontal_scroll_policy = "never"

    -- Add a top-level label for clarity
    tree_scroll.add{
        type = "label",
        caption = "Recipe breakdown:",
        style = "caption_label"
    }
    add_text_recipe_tree_to_gui(tree_scroll, recipe_results, 0, true)

    M.add_summed_requirements_to_gui(tree_scroll, recipe_results, sum_ingredients_table)
    
    add_tree_node(parent, {
        name = "iron-plate",
        item_amount_per_second = 10,
        machines_amount = 2
    })
end

return M