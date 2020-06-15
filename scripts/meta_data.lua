------------------------------------------------------------------------------------
-- Meta Data parse/stringify
------------------------------------------------------------------------------------
--- 出力レイヤーデータを復元する
--- [format] command[:export layer1,export layer2,...]
local function parse_export_v1(strdata)
    -- マスク対象等のレイヤを調べる
    local layer_types = split(strdata, ":")
    if #layer_types == 2 then
        local command = layer_types[1]
        local export_names = split(layer_types[2], ",")
        if #export_names > 0 then
            -- export layerが指定されている場合
            return command, export_names
        else
            -- export layerが指定されていない場合
            return command, {}
        end
    else
        -- export layerが指定されていない場合
        return strdata, {}
    end
end

--- 入力レイヤーデータを復元する
--- [format] target layer1,target layer2,...[:exclude layer1,exclude layer2,...]
local function parse_target_v1(strdata)
    local exclude_names = {}
    local target_names = {}
    -- マスク対象等のレイヤを調べる
    local layer_types = split(strdata, ":")
    if #layer_types == 2 then
        target_names = split(layer_types[1], ",")
        exclude_names = split(layer_types[2], ",")
    else
        target_names = split(strdata, ",")
    end
    return target_names, exclude_names
end

--- メタデータ文字列からデータを復元する
--- [format] command[:export layer1,export layer2,...]=target layer1,target layer2,...[:exclude layer1,exclude layer2,...]
local function parse_metadata_v1(strdata)
    local sp_layer_name = split(strdata, "=")
    if #sp_layer_name == 2 then
        local command, export_names = parse_export_v1(sp_layer_name[1])
        local target_names, exclude_names = parse_target_v1(sp_layer_name[2])
        return {
            command = command,
            export_names = export_names,
            target_names = target_names,
            exclude_names = exclude_names
        }
    else
        return nil
    end 
end

--- メタデータからメタデータ文字列を生成する
local function stringify_metadata_v1(metadata)
    local command = metadata["command"]
    local target_names = metadata["target_names"]
    local exclude_names = metadata["exclude_names"]
    local export_names = metadata["export_names"]

    local strdata = command
    if export_names~=nil and #export_names > 0 then
        strdata = strdata..":"..join(export_names, ",")
    end
    strdata = strdata.."="..join(target_names, ",")
    if exclude_names~=nil and #exclude_names > 0 then
        strdata = strdata..":"..join(exclude_names, ",")
    end
    return strdata
    
end

--- メタデータ文字列から元のデータを復元する
function RestoreMetaData(sprite, layer, metadata)
    local command = metadata["command"]
    local target_names = metadata["target_names"]
    local exclude_names = metadata["exclude_names"]
    local export_names = metadata["export_names"]
    
    local export_layers = {}
    local target_layers = {}
    local exclude_layers = {}
    if export_names ~= nil and #export_names >0 then
        search_layers(sprite.layers, export_names, export_layers)
    else
        export_layers = {layer}
    end
    search_layers(sprite.layers, target_names, target_layers)
    search_layers(sprite.layers, exclude_names, exclude_layers)
    --- TODO:マルチエクスポート対応する
    return command, target_layers, exclude_layers, export_layers[1]
end

function GetLayerMetaData(layer)
    local metadata = nil
    if layer.data ~= nil then
        metadata = parse_metadata_v1(layer.data)
        if metadata == nil then
            metadata = parse_metadata_v1(layer.name)
        end
    end
    return metadata
end

function GetCelMetaData(cel)
    local metadata = nil
    if cel.data ~= nil then
        metadata = parse_metadata_v1(cel.data)
    end
    return metadata
end

function RestoreLayerMetaData(layer)
    local metadata = GetLayerMetaData(layer)
    if metadata ~= nil then
        return RestoreMetaData(layer.sprite, layer, metadata)
    end
    
    return nil, nil, nil, nil
end

function RestoreCelMetaData(cel)
    local metadata = GetCelMetaData(cel)
    if metadata ~= nil then
        local layer = cel.layer
        return RestoreMetaData(layer.sprite, layer, metadata)
    end

    return nil, nil, nil, nil
end

function SetLayerMetaData(layer, metadata)
    if metadata == nil or metadata["command"] == nil then
        layer.data = ""
        return
    end
    layer.data = stringify_metadata_v1(metadata)
    layer.name = layer.data
end

function SetLayerCelData(cel, metadata)
    if metadata == nil or metadata["command"] == nil then
        cel.data = ""
        return
    end
    cel.data = stringify_metadata_v1(metadata)
end

function CreateDefaultMetaData()
    return {
        command = "mask",
        export_names = {},
        target_names = {},
        exclude_names = {}
    }
end