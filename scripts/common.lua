--- 指定文字で文字列を分割する
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

--- nameで指定したレイヤーを検索する
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

--- namesで指定した名前と一致するレイヤーを検索する
function search_layers(layers, names, found_layers)
    for i, name in pairs(names) do
        search_layer(layers, name, found_layers)
    end
end

--- レイヤーを検索する(正規表現)
function grep_layer(layers, str, found_layers)
    for i, layer in ipairs(layers) do
        if string.match(layer.name, str) ~= nil then
            found_layers[#found_layers+1] = layer
        end
        if layer.isGroup then
            search_layer(layer.layers, str, found_layers)
        end
    end
end

--- 配列内に指定した要素が存在するかチェックする
function contains(array, item)
    if array == nil then
        return false
    end
    for i,_item in ipairs(array) do
        if _item == item then
            return true
        end
    end
    return false
end

--- 配列内の要素を削除した上で詰め替える
function remove(array, index)
    if index > #array then
        return
    end
    local idx = 1
    for i,_item in ipairs(array) do
        if i~=idx then
            array[idx] = _item
        end
        if i~=index then
            idx = idx+1
        end
    end
    array[#array] = nil
end

--- 配列を指定した文字で結合する
function join(array, split)
    if array == nil or #array == 0 then
        return ""
    elseif #array == 1 then
        return array[1]
    end
    local joined = ""
    for i,_item in ipairs(array) do
        if i == 1 then
            joined = _item
        else
            joined = joined..split.._item
        end
    end
    return joined
end

function get_layer_name_list(layers)
    if layers == nil then
        return {}
    end
    local names = {}
    for i, v in pairs(layers) do
        if not contains(names, v.name) then
            names[#names+1] = v.name
        end
    end
    return names
end

function get_layer_name_list_for_range(layers)
    if layers == nil then
        return {}
    end
    local names = {}
    for i, v in ipairs(layers) do
        if not contains(names, v.name) then
            names[#names+1] = v.name
        end
    end
    return names
end

--- レイヤー配列から名前をカンマ結合した文字列を生成する
function join_layer_name(layers)
    local names = {}
    return join(get_layer_name_list(layers), ",")
end