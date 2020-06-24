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

--- 同一配列か調べる（順不同）
--- ただし重複要素は無いものとする
function same_array(array1, array2)
    if #array1 ~= #array2 then
        return false
    else
        for i, v in ipairs(array1) do
            if not contains(array2, v) then
                return false
            end
        end
    end
    return true
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

--- ２つの配列の共通項目を取得する（重複は削除される）
function intersect(array1, array2)
    if array1 == nil or #array1 == 0 then
        return {}
    end
    if array2 == nil or #array2 == 0 then
        return {}
    end
    local new_array = {}
    for i,v in ipairs(array1) do
        if contains(array2, v) and not contains(new_array, v) then
            new_array[#new_array+1] = v
        end
    end
    return new_array
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

function join_table(table1, table2)
    for i, v in pairs(table2) do
        if table2[i] ~= nil then
            table1[i] = table2[i]
        end
    end
    return table1
end

--- 一意のラベルを生成する
local random = math.random
function uid_gen()
    local timestamp = math.floor(os.clock() * 10000000)
    local fix = random(0, 9)
    local id = string.format("%x%d", fix, timestamp)
    return tonumber(id)
end

-----------------------------------------------------
-- AsepriteにないAPI
-----------------------------------------------------

--- baseFrameNumberで指定したセルとリンクしているセルの全FrameNumberを取得する
function SearchLinkedCels(layer, baseFrameNumber)
    local cel = layer:cel(baseFrameNumber)
    if cel == nil then return {} end

    local frameNumbers = {}
    local oldData = cel.data
    local uid = tostring(uid_gen())
    cel.data = uid

    local currentFrame = layer.sprite.frames[1]
    while currentFrame ~= nil do
        local cel = layer:cel(currentFrame)
        if cel ~= nil and cel.data == uid then
            frameNumbers[#frameNumbers+1] = currentFrame.frameNumber
        end
        currentFrame = currentFrame.next
    end
    cel.data = oldData

    return frameNumbers
end

function LinkCels(layer, frameNumbers)
    app.range.layers = {layer}
    app.range.frames = frameNumbers
    app.command.LinkCels()
end

function CopyCel(layer, srcFrameNumber, dstFrameNumber, isLinked)
    -- 以下のコードは動かない。
    -- なぜなら、Celに対するコピーはタイムラインにフォーカスが当たっていないと動かないが
    -- 現状タイムラインにフォーカスを移動させる方法がないため。
    -- local oldIsContinuous = layer.isContinuous
    -- layer.isContinuous = isLinked

    -- app.activeLayer = layer
    -- app.activeFrame = srcFrameNumber
    -- app.command.Copy()
    -- app.activeFrame = dstFrameNumber
    -- app.command.Paste()

    -- layer.isContinuous = oldIsContinuous

    if isLinked then
        local srcFrameNumbers = SearchLinkedCels(layer, srcFrameNumber)
        if #srcFrameNumbers == 0 then return end
        local minSrcFrameNumber = srcFrameNumbers[1]

        if dstFrameNumber < minSrcFrameNumber then
            -- 先頭のセルがリンクの基準になるため、一旦先頭のセルにデータをコピーする
            CopyCel(layer, minSrcFrameNumber, dstFrameNumber, false)
            -- リンクする
            LinkCels(layer, {minSrcFrameNumber, dstFrameNumber})
            -- リンクすると元々のリンクが切れるので復元する
            LinkCels(layer, srcFrameNumbers)
        else
            -- リンクする
            LinkCels(layer, {minSrcFrameNumber, dstFrameNumber})
        end
    else
        local srcCel = layer:cel(srcFrameNumber)
        if srcCel == nil then return end
        local dstCel = layer.sprite:newCel(layer, dstFrameNumber, srcCel.image, srcCel.position)
        dstCel.color = srcCel.color
        dstCel.data = srcCel.data
    end
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

-----------------------------------------------------
-- Extension専用API
-----------------------------------------------------
--- Cel検索結果キャッシュ（数が多いので検索結果をキャッシュする）
local _src_cel_search_cache = {}
local _export_layer_search_cache = {}
local _mask_layer_search_cache = {}

function CacheReset()
    _src_cel_search_cache = {}
    _export_layer_search_cache = {}
    _mask_layer_search_cache = {}
end

--- labelで指定したソースセルを取得する
local function is_target_src_cel(cel, label)
    local metadata = GetCelMetaData(cel)
    if metadata == nil or metadata.mt ~= METADATA_TYPE.LINK_CEL then
        return false
    end
    if not metadata.is_src then
        return false
    end
    --- キャッシュする
    _src_cel_search_cache[metadata.label] = cel
    return metadata.label == label
end

--- Source Celをラベルから検索する
function SearchSrcCelByLabel(sprite, label)
    if _src_cel_search_cache[label] ~= nil then
        return _src_cel_search_cache[label]
    end

    for i, cel in ipairs(sprite.cels) do
        if is_target_src_cel(cel, label) then
            return cel
        end
    end
    return nil   
end

local function _SearchExportLayerByLabel(sprite, layer, label)
    if layer.isGroup then
        for i, l in ipairs(layer.layers) do
            local found_layer = _SearchExportLayerByLabel(sprite, l, label)
            if found_layer ~= nil then
                return found_layer
            end
        end
    end

    local metadata = GetLayerMetaData(layer)
    if metadata == nil then
        return nil
    end

    if metadata.mt == METADATA_TYPE.EXPORT_LAYER then
        --- キャッシュする
        _export_layer_search_cache[metadata.label] = layer
    else
        return nil
    end

    if metadata.label == label then
        return layer
    end
    return nil
end

--- Export Layerをラベルから検索する
function SearchExportLayerByLabel(sprite, label)
    if _export_layer_search_cache[label] ~= nil then
        return _export_layer_search_cache[label]
    end

    for i, layer in ipairs(sprite.layers) do
        local export_layer = _SearchExportLayerByLabel(sprite, layer, label)
        if export_layer ~= nil then
            return export_layer
        end
    end
    return nil   
end

local function _SearchMaskLayerByLabel(sprite, layer, label)
    if layer.isGroup then
        for i, l in ipairs(layer.layers) do
            local found_layer = _SearchMaskLayerByLabel(sprite, l, label)
            if found_layer ~= nil then
                return found_layer
            end
        end
    end

    local metadata = GetLayerMetaData(layer)
    if metadata == nil then
        return nil
    end

    if metadata.mt == METADATA_TYPE.COMMAND
        or metadata.mt == METADATA_TYPE.DEFAULT then
        --- キャッシュする
        _mask_layer_search_cache[metadata.label] = layer
    else
        return nil
    end

    if metadata.label == label then
        return layer
    end
    return nil
end

--- Export Layerをラベルから検索する
function SearchMaskLayerByLabel(sprite, label)
    if _mask_layer_search_cache[label] ~= nil then
        return _mask_layer_search_cache[label]
    end

    for i, layer in ipairs(sprite.layers) do
        local export_layer = _SearchMaskLayerByLabel(sprite, layer, label)
        if export_layer ~= nil then
            return export_layer
        end
    end
    return nil   
end