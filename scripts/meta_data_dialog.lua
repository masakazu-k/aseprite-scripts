
local function LayerInputDialog(default, deletable)
    local dlg = Dialog("Edit")
    dlg:entry{ id="user_value", text=default}
    dlg:separator()
        dlg:button{ id="ok", text="OK" }
        dlg:button{ id="cancel", text="Cancel" }
    if deletable then
        dlg:button{ id="delete", text="Delete" }
    end
    dlg:show()

    local data = dlg.data
    if deletable and data.delete then
        return nil
    end
    if data.ok then
        return data.user_value
    end
    return default
end

local function DialogEditLayerList(dlg, label, array, prefix, reopen)
    dlg:label{text=label}
    for i,v in pairs(array) do
        dlg:newrow{}
        dlg:button{id=prefix..i, text=v,
        onclick=
        function ()
            local edited = LayerInputDialog(array[i], true)
            if edited == nil then
                remove(array, i)
                reopen()
            else
                array[i] = edited
                dlg:modify{ id=prefix..i, text=edited}
            end
        end
        }
    end
    
    dlg:newrow()
    dlg:button{ id="add", text="+",
    onclick=
    function ()
        local new_layer = LayerInputDialog("new layer", false)
        if not contains(array, new_layer) then
            array[#array+1] = new_layer
            reopen()
        end
    end
    }
end

local function EditDialogShow(metadata, save, position)
    if metadata == nil then
        metadata = CreateDefaultMetaData()
    end

    local dlg = Dialog("Mask Layer Config")
    if position ~= nil then
        dlg.bounds = position
    end
            
    dlg:combobox{ id="command", label="type", option=metadata["command"],
        options={ "mask", "imask", "merge", "outline"},
        onchange=
        function()
            metadata.command = dlg.data.command
        end
    }
    
    dlg:label{text="Export Layer"}
    local export_layer = ""
    if #metadata.export_names >0 then
        export_layer = metadata.export_names[1]
    end
    dlg:entry{id="export_layer", text=export_layer,
    onchange=
    function ()
        if #dlg.data.export_layer > 0 then
            metadata.export_names = {dlg.data.export_layer}
        end
    end
    }
    local reopen = function ()
        local bounds = dlg.bounds
        dlg:close()
        EditDialogShow(metadata, save, bounds)
    end
    DialogEditLayerList(dlg, "Target Layers", metadata.target_names, "target_layer_", reopen)
    DialogEditLayerList(dlg, "Exclude Layers", metadata.exclude_names, "exclude_layer_", reopen)

    --dlg:check{ id="export_to_self", label="export to self", text="", selected=false}

    dlg:separator()
    dlg:button{ id="apply", text="Apply" ,onclick=function () save(metadata) dlg:close() end}
    dlg:button{ id="cancel", text="Cancel" }
    dlg:button{ id="close", text="Close" }
    dlg:show()
end

function EditLayerMetaDataDialogShow()
    if #app.range.layers <= 0 then
        return
    end
    local layer = app.range.layers[1]
    local metadata = GetLayerMetaData(layer)
    if metadata == nil then
        metadata = CreateDefaultMetaData()
    end

    EditDialogShow(metadata,
    function (new_metadata)
        SetLayerMetaData(layer, new_metadata)
    end, nil)
end

function EditCelMetaDataDialogShow()
    if #app.range.layers <= 0 or #app.range.frames <= 0 then
        return
    end
    local layer = app.range.layers[1]
    local frameNumber = app.range.frames[1].frameNumber
    local cel = layer:cel(frameNumber)
    local metadata = nil
    if cel ~= nil then
        metadata = GetCelMetaData(cel)
    else
        metadata = GetLayerMetaData(layer)
    end
    if metadata == nil then
        metadata = CreateDefaultMetaData()
    end

    EditDialogShow(metadata,
    function (new_metadata)
        for i, v in ipairs(app.range.frames) do
            local cel = layer:cel(v.frameNumber)
            if cel == nil then
                cel = app.activeSprite:newCel(layer, v)
            end
            SetCelMetaData(cel, new_metadata)
        end
    end, nil)
end

--- target_layerと同一階層の一番上に指定名のレイヤーを作成する
--- force_createがfalseの場合、同一名のレイヤーが存在しない場合のみ作成する
local function CreateLayerTop(target_layer, name, fource_create)
    if not fource_create then
        local found_layers = {}
        search_layer(app.activeSprite.layers, name, found_layers)
        if #found_layers>0 then
            return found_layers[1]
        end
    end
    local new_layer = app.activeSprite:newLayer()
    new_layer.parent = target_layer.parent
    new_layer.stackIndex = #target_layer.parent.layers
    new_layer.name = name
    return new_layer
end

function CreateLayerMetaDataDialogShow()
    if #app.range.layers <= 0 then
        return
    end
    local last_layer = app.range.layers[1]
    local target_names = get_layer_name_list_for_range(app.range.layers)
    local metadata = CreateDefaultMetaData()
    metadata.target_names = target_names
    metadata.export_names = {"$masked"}
    
    EditDialogShow(metadata,
    function (new_metadata)
        -- マスクレイヤーの作成
        local mask_layer = CreateLayerTop(last_layer, "", true)
        SetLayerMetaData(mask_layer, new_metadata)

        -- エクスポートレイヤーの作成
        CreateLayerTop(last_layer, metadata.export_names[1], false)
    end, nil)
end