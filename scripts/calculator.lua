local util = require("scripts.util")

local M = {}

-- Calculate resource requirements for a given item and production rate
function M.calculate_requirements(target_item_name, target_production_rate, assembler_speed, furnace_speed, drill_speed)
    local recipe = prototypes.recipe[target_item_name]
    local recipe_table = {}
    local ingredients_table = {}
    local machine_speed = 1

    if recipe == nil then
        local found_prototype = nil
        local raw_types = { "iron-ore", "copper-ore", "coal", "stone", "crude-oil", "uranium-ore" }
        for _, raw_type in ipairs(raw_types) do
            if target_item_name == raw_type then
                if target_item_name == "crude_oil" then
                    machine_speed = 1 -- Crude oil is extracted with a pumpjack, which has a fixed speed
                else
                    machine_speed = drill_speed
                end
                break
            end
        end
        found_prototype = util.find_prototype_by_name(target_item_name)
        if found_prototype then
            local machines_amount = target_production_rate / machine_speed
            -- If the raw ingredient is a fluid, no need to specify machines amount
            if found_prototype.type == "fluid" then
                machines_amount = nil
            end
            local final_item_table = {
                name = found_prototype.name,
                type = found_prototype.type,
                item_amount_per_second = target_production_rate,
                machines_amount = machines_amount
            }
            return final_item_table
        else
            return {name = target_item_name, item_amount_per_second = target_production_rate, type = "unknown"}
        end
    end

    if recipe.main_product.type == "fluid" then
        machine_speed = 1 -- fluids are processed in chemical plants or refineries, which have a fixed speed
    elseif recipe.category == "smelting" then
        machine_speed = furnace_speed
    elseif recipe.category == "crafting" or recipe.category == "advanced-crafting" or recipe.category == "crafting-with-fluid" then
        machine_speed = assembler_speed
    end
    
    local default_production_rate_per_second = recipe.main_product.amount / recipe.energy
    local process_amount = target_production_rate / recipe.main_product.amount
    local total_time = process_amount * recipe.energy 
    local machines_amount = total_time / machine_speed
    local adjusted_production_rate = target_production_rate / default_production_rate_per_second

    for _, ingredient in pairs(recipe.ingredients) do
        table.insert(ingredients_table, M.calculate_requirements(
            ingredient.name, 
            ingredient.amount * process_amount,
            assembler_speed,
            furnace_speed,
            drill_speed
        ))
    end
    recipe_table = {
        name = target_item_name,
        type = recipe.main_product.type,
        item_amount_per_second = target_production_rate,
        process_amount_per_second = process_amount,
        machines_amount = machines_amount,
        energy = recipe.energy,
        ingredients = ingredients_table
    }

    return recipe_table
end


-- Sum the ingredients requirements recursively
function M.sum_requirements(recipe_results, sum_ingredients_table)
    local name = recipe_results.name
    local amount = recipe_results.item_amount_per_second
    if sum_ingredients_table[name] == nil then
        sum_ingredients_table[name] = amount
    else
        sum_ingredients_table[name] = sum_ingredients_table[name] + amount
    end
    if not recipe_results.ingredients then
        return
    end
    
    -- recursively traverse the recipe results and sum up the ingredients
    for _, ingredient in pairs(recipe_results.ingredients) do
        M.sum_requirements(ingredient, sum_ingredients_table)
    end
end

return M