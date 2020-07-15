--- base_layerと同一階層の一番上に指定名のレイヤーを作成する
--- force_createがfalseの場合、同一名のレイヤーが存在しない場合のみ作成する
local function CreateLayerTop(base_layer, name)
    local new_layer = app.activeSprite:newLayer()
    new_layer.parent = base_layer.parent
    new_layer.stackIndex = #base_layer.parent.layers
    new_layer.name = name
    return new_layer
end

local function CreateMaskLayer(base_layer, mask_metadata)
    local name = mask_metadata.command .. "(" .. join(mask_metadata.include_names,",") .. ")"
    local mask_layer = CreateLayerTop(base_layer, name)
    SetLayerMetaData(mask_layer, mask_metadata)
    return mask_layer
end

local function CreateExportLayer(base_layer, mask_metadata)
     local name = mask_metadata.export_names[1]
     local export_metadata = CreateExportLayerMetaData(mask_metadata.label)
     local export_layer = CreateLayerTop(base_layer, name)
     SetLayerMetaData(export_layer, export_metadata)
     return export_layer
end

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

local function EditDialogShow(metadata, is_layer, save, position)
    if metadata == nil then
        metadata = CreateMaskMetaData()
    end

    local dlg = Dialog("Mask Layer Config")
    if position ~= nil then
        dlg.bounds = position
    end
            
    dlg:combobox{ id="command", label="type", option=metadata["command"],
        options={ 
            COMMAND_TYPE.MERGE,
            COMMAND_TYPE.MASK,
            COMMAND_TYPE.INVERSE_MASK,
            COMMAND_TYPE.OUTLINE},
        onchange=
        function()
            metadata.command = dlg.data.command
        end
    }

    local reopen = function ()
        local bounds = dlg.bounds
        dlg:close()
        EditDialogShow(metadata, is_layer, save, bounds)
    end

    if not is_layer then
        dlg:check{id="inherit",text="Use Layer Config", selected=metadata.inherit,
        onclick=
        function ()
            metadata.inherit=dlg.data.inherit
            reopen()
        end
        }
    end

    if not metadata.inherit or is_layer then
        dlg:label{text="Export Layer (Copy to)"}
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

        dlg:label{text="Source Layer (Copy from)"}
        dlg:newrow()
        DialogEditLayerList(dlg, "Include Layers", metadata.include_names, "include_layer_", reopen)
        DialogEditLayerList(dlg, "Exclude Layers", metadata.exclude_names, "exclude_layer_", reopen)
    end

    dlg:separator()
    -- dlg:label{text="Offset"}
    -- local setOffset = function ()
    --     metadata.offset_x = dlg.data.offset_x
    --     metadata.offset_y = dlg.data.offset_y
    --     -- local layer = app.activeLayer
    --     -- local cel = layer:cel(app.activeFrame.frameNumber)
    --     -- if cel ~= nil then
    --     --     SetCelOffsetX(cel, metadata.offset_x, metadata.offset_y)
    --     --     app.refresh()
    --     -- end
    -- end
    -- dlg:number{id="offset_x", label="x", decimals=metadata.offset_x, onchange=setOffset}
    -- dlg:number{id="offset_y", label="y", decimals=metadata.offset_y, onchange=setOffset}

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
        metadata = CreateMaskMetaData()
    end

    EditDialogShow(metadata, true,
    function (mask_metadata)
        --- TODO 後方互換用の処理 後で取り除く
        if mask_metadata.label == nil then
            mask_metadata.label = uid_gen()
        end
        SetLayerMetaData(layer, mask_metadata)

        local export_layer = SearchExportLayerByLabel(app.activeSprite, mask_metadata.label)
        if export_layer == nil then
            -- エクスポートレイヤーの作成
            CreateExportLayer(layer, mask_metadata)
        end
    end, nil)
end

function EditCelMetaDataDialogShow()
    if #app.range.layers <= 0 or #app.range.frames <= 0 then
        return
    end
    local layer = app.range.layers[1]
    local frameNumber = app.range.frames[1].frameNumber
    local cel = layer:cel(frameNumber)
    local metadata = GetLayerMetaData(layer)

    if metadata == nil 
    or (metadata.mt ~= METADATA_TYPE.COMMAND and metadata.mt ~= METADATA_TYPE.DEFAULT) then
        app.alert("This layer is NOT mask layer.")
        return
    end

    if cel ~= nil then
        metadata = GetCelMetaData(cel)
    else
        metadata = GetLayerMetaData(layer)
    end

    EditDialogShow(metadata, false,
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

function CreateLayerMetaDataDialogShow()
    if #app.range.layers <= 0 then
        return
    end
    local last_layer = app.range.layers[1]
    local include_names = get_layer_name_list_for_range(app.range.layers)
    local metadata = CreateMaskMetaData()
    metadata.include_names = include_names
    metadata.export_names = {"$export_layer"}
    
    EditDialogShow(metadata, true,
    function (mask_metadata)
        -- マスクレイヤーの作成
        CreateMaskLayer(last_layer, mask_metadata)
        -- エクスポートレイヤーの作成
        CreateExportLayer(last_layer, mask_metadata)
    end, nil)
end

function PropViewDialogShow()
    if #app.range.layers <= 0 or #app.range.frames <= 0 then
        return
    end
    local layer = app.range.layers[1]
    local frameNumber = app.range.frames[1].frameNumber
    local cel = layer:cel(frameNumber)
    if cel ~= nil then
        local metadata = GetMetaData(layer, frameNumber)
        if metadata == nil then return end
        local dlg = Dialog("Debug")
        dlg:label{
            text = "offset x: "..tostring(metadata.offset_x)
        }
        dlg:label{
            text = "offset y: "..tostring(metadata.offset_y)
        }
        dlg:button{
            text = "Auto Color Set",
            onclick = function ()
                app.transaction(
                    function ()
                        ResetCelsColor(layer.sprite)
                        app.refresh()
                    end
                )
            end
        }
        dlg:button{
            text = "Close"
        }
        dlg:show()
    end
end