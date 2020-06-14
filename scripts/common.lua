-- 文字列分割
function split(str, ts)
    -- 引数がないときは空tableを返す
    if ts == nil then return {} end

    local t = {}
    i=1
    for s in string.gmatch(str, "([^"..ts.."]+)") do
        t[i] = s
        i = i + 1
    end

    return t
end

--- レイヤーを検索する
function search_layer(layers, name, found_layers)
    for i, layer in ipairs(layers) do
        if layer.name == name then
            found_layers[#found_layers+1] = layer
        end
        if layer.isGroup then
            search_layer(layer.layers, name, found_layers)
        end
    end
end

function contains(array, item)
    if array == nil then
        return true
    end
    for i,_item in ipairs(array) do
        if _item == item then
            return false
        end
    end
    return true
end