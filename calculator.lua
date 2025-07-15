local M = {}

-- Function to calculate resource requirements for a given item and production rate
function M.calculate_requirements(target_item_name, target_production_rate, machine_speed)
    local recipe = prototypes.recipe[target_item_name]
    local recipe_table = {}
    local ingredients_table = {}
    local player = game.players[1] 

    if recipe == nil then
        local found_prototype = nil
        local proto_types = {"item", "fluid", "tool", "ammo", "capsule", "armor", "gun", "module", "rail-planner", "repair-tool", "mining-tool", "item-with-entity-data", "item-with-inventory", "item-with-label", "item-with-tags", "item-with-entity-data"}
        for _, proto_type in ipairs(proto_types) do
            if prototypes[proto_type] and prototypes[proto_type][target_item_name] then
                found_prototype = prototypes[proto_type][target_item_name]
                break
            end
        end
        if found_prototype then
            local final_item_table = {
                name = found_prototype.name,
                type = found_prototype.type,
                item_amount_per_second = target_production_rate
            }
            return final_item_table
        else
            return {name = target_item_name, item_amount_per_second = target_production_rate, type = "unknown"}
        end
    end

    local default_production_rate_per_second = recipe.main_product.amount / recipe.energy
    local process_amount = target_production_rate / recipe.main_product.amount
    local total_time = process_amount * recipe.energy 
    local machines_amount = total_time * machine_speed
    local adjusted_production_rate = target_production_rate / default_production_rate_per_second

    for _, ingredient in pairs(recipe.ingredients) do
        table.insert(ingredients_table, M.calculate_requirements(
            ingredient.name, 
            ingredient.amount * process_amount,
            machine_speed
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