------------------------------------------------------------------------------------
-- Meta Data const value
------------------------------------------------------------------------------------

--- メタデータの種別
METADATA_TYPE = {
    --- 後方互換用
    DEFAULT    = nil,
    --- コマンドレイヤ／セル
    COMMAND    = 1,
    --- Source/Distinationセル
    LINK_CEL   = 2,
    --- Exportレイヤ
    EXPORT_LAYER = 3,
    --- Exportセル
    EXPORT_CEL = 4
}

--- コマンドの種別
COMMAND_TYPE = {
    MASK         = "mask",
    INVERSE_MASK = "imask",
    MERGE        = "merge",
    OUTLINE      = "outline"
}
------------------------------------------------------------------------------------
-- Meta Data struct
------------------------------------------------------------------------------------

--- マスクレイヤ／セルに設定するメタデータ
function CreateMaskMetaData()
    return {
        mt = METADATA_TYPE.COMMAND,
        ver = "v2",
        label = uid_gen(),
        inherit = true,
        command = COMMAND_TYPE.MERGE,
        export_names = {},
        include_names = {},
        exclude_names = {},
        offset_x = 0,
        offset_y = 0,
        locked = false
    }
end

--- Exportレイヤに設定するメタデータ
function CreateExportLayerMetaData(label)
    return {
        mt = METADATA_TYPE.EXPORT_LAYER,
        --- 関連するマスクレイヤのラベル
        label = label
    }
end

--- Exportセルに設定するメタデータ
function CreateExportCelMetaData(label)
    return {
        mt = METADATA_TYPE.EXPORT_CEL,
        --- 関連するマスクレイヤのラベル
        label = label,
        offset_x = 0,
        offset_y = 0,
        locked = false
    }
end

--- Source/Distinationセルに設定するメタデータ
function CreateLinkMetaData()
    return {
        mt = METADATA_TYPE.LINK_CEL,
        label = uid_gen(),
        inherit = true,
        offset_x = 0,
        offset_y = 0,
        is_src = false,
        locked = false
    }
end

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
--- [format] include layer1,include layer2,...[:exclude layer1,exclude layer2,...]
local function parse_source_v1(strdata)
    local exclude_names = {}
    local include_names = {}
    -- マスク対象等のレイヤを調べる
    local layer_types = split(strdata, ":")
    if #layer_types == 2 then
        include_names = split(layer_types[1], ",")
        exclude_names = split(layer_types[2], ",")
    else
        include_names = split(strdata, ",")
    end
    return include_names, exclude_names
end

--- メタデータ文字列からデータを復元する
--- [format] command[:export layer1,export layer2,...]=include layer1,include layer2,...[:exclude layer1,exclude layer2,...]
local function parse_metadata_v1(strdata)
    local sp_layer_name = split(strdata, "=")
    if #sp_layer_name == 2 then
        local command, export_names = parse_export_v1(sp_layer_name[1])
        local include_names, exclude_names = parse_source_v1(sp_layer_name[2])
        return {
            ver = "v1",
            inherit = true,
            command = command,
            export_names = export_names,
            include_names = include_names,
            exclude_names = exclude_names,
            offset_x = 0,
            offset_y = 0
        }
    else
        return nil
    end 
end

--- メタデータからメタデータ文字列を生成する
local function stringify_metadata_v1(metadata)
    local command = metadata["command"]
    local include_names = metadata["include_names"]
    local exclude_names = metadata["exclude_names"]
    local export_names = metadata["export_names"]

    local strdata = command
    if export_names~=nil and #export_names > 0 then
        strdata = strdata..":"..join(export_names, ",")
    end
    strdata = strdata.."="..join(include_names, ",")
    if exclude_names~=nil and #exclude_names > 0 then
        strdata = strdata..":"..join(exclude_names, ",")
    end
    return strdata
    
end

local stringify_table = nil
local function stringify_data(data)
    local types = type(data)
    if types == nil then
        return "nil"
    elseif types == "string" then
        return "\"" .. string.gsub(data, "\"", "\\\"") .. "\""
    elseif types == "number" or types == "boolean" then
        return tostring(data)
    else
        return stringify_table(data)
    end
end

stringify_table = function (data)
    local strdata = "{"
    local check = false
    for i, v in pairs(data) do
        if check then
            strdata = strdata..","
        end
        if type(i) == "number" then
            strdata = strdata..stringify_data(v)
        else
            strdata = strdata..tostring(i).."="..stringify_data(v)
        end
        check = true
    end
    strdata = strdata.."}"
    return strdata
end

function stringify_metadata_v2(metadata)
    metadata["ver"] = "v2"
    return "return "..stringify_table(metadata)
end

function parse_metadata_v2(strdata)
    local f,e = load(strdata)
    if f==nil then
        return nil
    end
    return f()
end

--- メタデータ文字列から元のデータを復元する
function RestoreMetaData(sprite, layer, metadata)
    local command = metadata["command"]
    local include_names = metadata["include_names"]
    local exclude_names = metadata["exclude_names"]
    local export_names = metadata["export_names"]
    
    local export_layers = {}
    local include_layers = {}
    local exclude_layers = {}
    if export_names ~= nil and #export_names >0 then
        search_layers(sprite.layers, export_names, export_layers)
    else
        export_layers = {layer}
    end
    search_layers(sprite.layers, include_names, include_layers)
    search_layers(sprite.layers, exclude_names, exclude_layers)

    return {
        command = command,
        export_layer = export_layers[1],
        export_layers = export_layers,
        include_layers = include_layers,
        exclude_layers = exclude_layers
    }
end

function GetLayerMetaData(layer)
    local metadata = nil
    if layer.data ~= nil and #layer.data > 0 then
        metadata = parse_metadata_v2(layer.data)
        if metadata == nil then
            metadata = parse_metadata_v1(layer.data)
            if metadata == nil then
                metadata = parse_metadata_v1(layer.name)
            end
        end
    end
    return metadata
end

function GetCelMetaData(cel)
    local metadata = nil
    if cel.data ~= nil and #cel.data > 0 then
        metadata = parse_metadata_v2(cel.data)
        if metadata == nil then
            metadata = parse_metadata_v1(cel.data)
        end
    end
    return metadata
end

function inherit_metadata(child, parent)
    child.command = parent.command
    child.export_names = parent.export_names
    child.include_names = parent.include_names
    child.exclude_names = parent.exclude_names
    return child
end

--- LayerとCelからメタデータを読み込む
--- Celのメタデータが優先される
--- inheritがtrueの場合はLayerのメタデータが一部優先される
function GetMetaData(layer, frameNumber)
    local layer_metadata = GetLayerMetaData(layer)
    local cel_metadata = nil
    local c = layer:cel(frameNumber)
    if c ~= nil then
        cel_metadata = GetCelMetaData(c)
    end
    
    if cel_metadata ~= nil and layer_metadata ~= nil then
        if cel_metadata.inherit == true or cel_metadata.inherit == nil then
            -- 親（レイヤ）の設定から継承する場合
            cel_metadata = inherit_metadata(cel_metadata, layer_metadata)
            return cel_metadata
        end
        return join_table(layer_metadata, cel_metadata)
    elseif layer_metadata ~= nil then
        return layer_metadata
    elseif cel_metadata ~= nil then
        return cel_metadata
    end
    return nil
end

function RestoreCommandData(layer, frameNumber)
    local metadata = GetMetaData(layer, frameNumber)
    if metadata ~= nil then
        return metadata, RestoreMetaData(layer.sprite, layer, metadata)
    end
    return nil, nil
end

function GetColor(metadata)
    if metadata.locked~=nil and metadata.locked then
        -- ロックされているセル／レイヤの色
        return Color{ r=0, g=143, b=141, a=100 }
    end
    -- 通常のセル／レイヤの色
    return Color{ r=115, g=0, b=255, a=100 }
end

function SetLayerMetaData(layer, metadata)
    if metadata == nil then
        layer.data = ""
        layer.color = Color{r=0, g=0, b=0, a=0}
        return
    end
    if metadata.mt == METADATA_TYPE.DEFAULT then
        metadata.mt = METADATA_TYPE.COMMAND
    end
    if metadata.mt == METADATA_TYPE.COMMAND then
        layer.data = stringify_metadata_v2(metadata)
        layer.color = GetColor(metadata)
    elseif metadata.mt == METADATA_TYPE.EXPORT_LAYER then
        layer.data = stringify_metadata_v2(metadata)
        layer.color = Color{ r=87, g=185, b=254, a=100 }
    end
end

function SetCelMetaData(cel, metadata)
    if metadata == nil then
        cel.data = ""
        cel.color = Color{r=0, g=0, b=0, a=0}
        return
    end
    if metadata.mt == METADATA_TYPE.COMMAND
     or metadata.mt == METADATA_TYPE.DEFAULT then
        if metadata == nil or metadata["command"] == nil then
            cel.data = ""
            return
        end
        cel.data = stringify_metadata_v2(metadata)
        cel.color = GetColor(metadata)
    elseif metadata.mt == METADATA_TYPE.LINK_CEL then
        cel.data = stringify_metadata_v2(metadata)
        -- TODO 別メソッドに出す
        if metadata.is_src then
            cel.color = Color{ r=254, g=91, b=89, a=100 }
        else
            cel.color = Color{ r=87, g=185, b=254, a=100 }
        end
    elseif metadata.mt == METADATA_TYPE.EXPORT_CEL then
        cel.data = stringify_metadata_v2(metadata)
        cel.color = Color{ r=87, g=185, b=254, a=100 }
    end
end

function CreateDefaultCommandData()
    return {
        command = "mask",
        export_layers = {},
        include_layers = {},
        exclude_layers = {}
    }
end
