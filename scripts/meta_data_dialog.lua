
local function TextInputDialog(default)
    local dlg = Dialog()
    dlg:entry{ id="user_value", text=default}
    dlg:separator()
    dlg:button{ id="ok", text="OK" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()

    local data = dlg.data
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
            local edited = TextInputDialog(array[i])
            array[i] = edited
            dlg:modify{ id=prefix..i, text=edited}
        end
        }
    end
    
    dlg:newrow()
    dlg:button{ id="add", text="+",
    onclick=
    function ()
        local new_layer = TextInputDialog("new layer")
        if not contains(array, new_layer) then
            array[#array+1] = new_layer
            reopen()
        end
    end
    }
    dlg:button{ id="del", text="-", 
    onclick=
    function ()
        app.alert("click "..tostring(i))
    end
    }
end

local function EditDialogShow(metadata, save, position)
    if metadata == nil then
        metadata = CreateDefaultMetaData()
    end

    local dlg = Dialog()
    if position ~= nil then
        dlg.bounds = position
    end
            
    dlg:combobox{ id="command", label="type", option=metadata["command"],
        options={ "mask", "merge", "outline" },
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
        local mask_layer = app.activeSprite:newLayer()
        mask_layer.parent = last_layer.parent
        mask_layer.stackIndex = last_layer.stackIndex+1
        SetLayerMetaData(mask_layer, new_metadata)
        local export_layers = {}
        search_layers(app.activeSprite.layers, metadata.export_names, export_layers)
        if #export_layers <= 0 then
            local export_layer = app.activeSprite:newLayer()
            export_layer.parent = mask_layer.parent
            export_layer.stackIndex = mask_layer.stackIndex+1
            export_layer.name = metadata.export_names[1]
        end
    end, nil)
end