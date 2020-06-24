local function add_layer(layer, layers)
    if layer.isGroup then
        for i,l in ipairs(layer.layers) do
            add_layer(l, layers)
        end
    end
    layers[#layers+1] = layer
end

--- 処理対象のフレームとレイヤを取得する
local function GetTargetLayerAndFrameNumbers(is_all_frame)
    local frameNumbers = {}
    local layers = {}
    if app.range.type == RangeType.LAYERS or is_all_frame then
        for i,f in ipairs(app.activeSprite.frames) do
            frameNumbers[#frameNumbers+1] = f.frameNumber
        end
    else
        for i,f in ipairs(app.range.frames) do
            frameNumbers[#frameNumbers+1] = f.frameNumber
        end
    end

    for i,l in ipairs(app.range.layers) do
        add_layer(l, layers)
    end
    return layers, frameNumbers
end

local function Update(is_all_frame)
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    
    app.transaction(
        function()
            local layers, frameNumbers = GetTargetLayerAndFrameNumbers(is_all_frame)
            for i,layer in ipairs(layers) do
                local metadata = GetLayerMetaData(layer)
                if metadata == nil then
                    CopyFromSrcCels(layer, frameNumbers)
                elseif metadata.mt == METADATA_TYPE.COMMAND then
                    -- 何もしない
                elseif metadata.mt == METADATA_TYPE.EXPORT_LAYER then
                    DoMergeCommand(layer, frameNumbers)
                end
            end
        end
    )
    CacheReset()
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
end

local function Store(is_all_frame)
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    app.transaction(
        function()
            local layers, frameNumbers = GetTargetLayerAndFrameNumbers(is_all_frame)
            for i,layer in ipairs(layers) do
                local metadata = GetLayerMetaData(layer)
                if metadata == nil then
                    StoreOffsetFromSrcCels(layer, frameNumbers)
                elseif metadata.mt == METADATA_TYPE.COMMAND then
                    -- 何もしない
                elseif metadata.mt == METADATA_TYPE.EXPORT_LAYER then
                    StoreMergeOffsetCels(layer, frameNumbers)
                end
            end
        end
    )
    CacheReset()
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
end

function UpdateSelected()
    Update(false)
    app.refresh()
end

function UpdateAll()
    Update(true)
    app.refresh()
end

function StoreSelected()
    Store(false)
    app.refresh()
end

function StoreAll()
    Store(true)
    app.refresh()
end


function CopySrcCels()
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    app.transaction(
        function()
            local layers, frameNumbers = GetTargetLayerAndFrameNumbers(false)
            for i,layer in ipairs(layers) do
                CopyFromRange(layer, frameNumbers)
            end
        end
    )
    CacheReset()
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
end

function PasteSrcCels()
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    app.transaction(
        function()
            local layers, frameNumbers = GetTargetLayerAndFrameNumbers(false)
            for i,layer in ipairs(layers) do
                PasteToRange(layer, frameNumbers)
            end
        end
    )
    CacheReset()
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
end