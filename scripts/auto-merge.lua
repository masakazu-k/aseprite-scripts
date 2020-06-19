
-------------------------------------------------------------------------------
-- 共通ここから
-------------------------------------------------------------------------------

local function MaskByColorOnCel(cel)
    local points = {}
    if cel ~= nil then
      for it in cel.image:pixels() do
        local pixelValue = it() -- get pixel
        if app.pixelColor.rgbaA(pixelValue) > 0 then
          points[#points + 1] = Point(it.x + cel.position.x, it.y + cel.position.y)
        end
      end
    end
    if #points <= 0 then
        return
    end
    local select = Selection()
    for i = 1, #points do
      local p = points[i]
      local r = Rectangle(p.x, p.y, 1 ,1)
      -- マスク対象エリアを選択
      select:add(Selection(r))
    end
    return select
end

local function MaskByColorOnLayer(layer, frameNumber, selected_layers, exclude_layers)
    local select = Selection()
    -- app.alert(layer.name)
    if layer.isImage and not contains(exclude_layers, layer) then
        -- MaskByColorOnCel(layer, frameNumber)
        select:add(MaskByColorOnCel(layer:cel(frameNumber)))
        selected_layers[#selected_layers+1] = layer
    elseif layer.isGroup then
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            select:add(MaskByColorOnLayer(l, frameNumber, selected_layers, exclude_layers))
        end
    end
    return select
end

local function MaskByColorOnSelect()
    local selected_layers = {}
    -- app.command.MaskByColor()
    for i=1, #app.range.layers do
        local layer = app.range.layers[i]
        if layer.isVisible then
            MaskByColorOnLayer(layer, app.activeFrame.frameNumber, selected_layers)
        end
    end
    return selected_layers
end

local function MaskByColorOnLayers(layers, frameNumber, exclude_layers)
    local selected_layers = {}
    local select = Selection()
    -- app.command.MaskByColor()
    for i=1, #layers do
        local layer = layers[i]
        if layer.isVisible then
            select:add(MaskByColorOnLayer(layer, frameNumber, selected_layers, exclude_layers))
        end
    end
    return selected_layers, select
end

local function GetMaskTargetList(layer, frameNumber, include_layers, exclude_layers)
    if layer.isImage and not contains(exclude_layers, layer) then
        include_layers[#include_layers+1] = layer
    elseif layer.isGroup then
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            GetMaskTargetList(l, frameNumber, include_layers, exclude_layers)
        end
    end
end

local function GetAllMaskTargetList(layers, frameNumber, exclude_layers)
    local include_layers = {}
    for i=1, #layers do
        local layer = layers[i]
        if layer.isVisible then
            GetMaskTargetList(layer, frameNumber, include_layers, exclude_layers)
        end
    end
    return include_layers
    
end
local function SwitchVisible(layer, excludes, layers)
    if layer.isImage and layer.isVisible and not contains(excludes, layer) then
          layers[#layers+1] = layer
          layer.isVisible = false
    elseif layer.isGroup then
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            SwitchVisible(l, excludes, layers)
        end
    end
    return layers
end
  
local function SwitchVisibleAll(sprite, excludes)
      local layers = {}
      for i,l in ipairs(sprite.layers) do
          SwitchVisible(l, excludes, layers)
      end
      return layers
end

--- 選択範囲の原点とセルの原点を比較しオフセットを取得する
function GetCelOffset(cel, select)
    return select.origin.x - cel.position.x, select.origin.y - cel.position.y
end

--- セルの原点をオフセット分移動する
function SetCelOffsetX(cel, offset_x, offset_y)
    local p = Point{
        x=cel.position.x - offset_x,
        y=cel.position.y - offset_y
    }
    cel.position = p 
end

-------------------------------------------------------------------------------
-- 共通ここまで
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- メイン処理
--
-------------------------------------------------------------------------------

local function SaveOffset(layer, frameNumber)
    
    local metadata, command, include_layers, exclude_layers, export_layer = RestoreCommandData(layer, frameNumber)

    if command == nil then
        return
    end
    local cel = export_layer:cel(frameNumber)
    if cel == nil then
        return
    end
    app.command.DeselectMask()
    local selected_layers, select = MaskByColorOnLayers(include_layers, frameNumber, exclude_layers)

    local offset_x, offset_y = GetCelOffset(cel, select)
    metadata.offset_x = offset_x
    metadata.offset_y = offset_y
    metadata.ver = "v2"

    cel = layer:cel(frameNumber)
    if cel == nil then
        cel = app.activeSprite:newCel(layer, frameNumber)
    end
    SetCelMetaData(cel, metadata)
end

local function  doExecute(layer, frameNumber)

    local metadata, command, include_layers, exclude_layers, export_layer = RestoreCommandData(layer, frameNumber)
    
    if command == nil then
        return
    end

    if command == "merge" then
        app.command.DeselectMask()
        local selected_layers, select = MaskByColorOnLayers(include_layers, frameNumber, exclude_layers)
        local unvisile_layers = SwitchVisibleAll(layer.sprite, selected_layers)

        if select.isEmpty then
            for i,l in ipairs(unvisile_layers) do
                l.isVisible = true
            end
            return false
        end
        layer.sprite.selection:add(select)

        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.command.ClearCel()
        app.command.CopyMerged()
    
        for i,l in ipairs(unvisile_layers) do
            l.isVisible = true
        end

        if metadata.ver == "v2" then
            SetCelOffsetX(layer:cel(frameNumber), metadata.offset_x, metadata.offset_y)
        end
        return true, metadata
    end

    if command == "outline" then
        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.command.DeselectMask()

        local selected_layers, select = MaskByColorOnLayers(include_layers, frameNumber, exclude_layers)
        app.command.ModifySelection{ modifier="expand", quantity=1, brush="circle" }
        layer.sprite.selection:add(select)

        app.command.ClearCel()
        app.command.Fill()

        app.command.DeselectMask()
        return false
    end

    if command == "mask" or command == "imask" then
        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.command.DeselectMask()

        local select = MaskByColorOnLayer(layer, frameNumber, {}, exclude_layers)
        local selected_layers = GetAllMaskTargetList(include_layers, frameNumber, exclude_layers)
        local unvisile_layers = SwitchVisibleAll(layer.sprite, selected_layers)

        if select.isEmpty then
            for i,l in ipairs(unvisile_layers) do
                l.isVisible = true
            end
            return false
        end
        layer.sprite.selection:add(select)

        if command == "imask" then
            app.command.InvertMask()
        end

        app.command.CopyMerged()
        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.command.ClearCel()
    
        for i,l in ipairs(unvisile_layers) do
            l.isVisible = true
        end
        app.command.DeselectMask()

        return true, metadata
    end

end

function SelectTargetLayer()
    local frameNumber = app.range.frames[1].frameNumber
    local layer = app.range.layers[1]
    local metadata, command, include_layers, exclude_layers, export_layer = RestoreCommandData(layer, frameNumber)
    if command == nil then
        return false
    end
    app.command.DeselectMask()

    local select = MaskByColorOnLayers(include_layers, frameNumber, exclude_layers)
    layer.sprite.selection:add(select)
end

local function add_layer(layer, layers)
    if layer.isGroup then
        for i,l in ipairs(layer.layers) do
            add_layer(l, layers)
        end
    end
    layers[#layers+1] = layer
end

function SaveCelsOffset()
    local frameNumbers = {}
    local layers = {}
    
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    for i,f in ipairs(app.range.frames) do
        frameNumbers[#frameNumbers+1] = f.frameNumber
    end

    for i,l in ipairs(app.range.layers) do
        add_layer(l, layers)
    end
    
    app.transaction(
        function()
            for i,frameNumber in ipairs(frameNumbers) do
                for i,layer in ipairs(layers) do
                    SaveOffset(layer,frameNumber)
                end
            end
        end
    )
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end

function AutoMerge()
    local paste = false
    local metadata = nil
    local frameNumbers = {}
    local layers = {}
    
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    for i,f in ipairs(app.range.frames) do
        frameNumbers[#frameNumbers+1] = f.frameNumber
    end

    for i,l in ipairs(app.range.layers) do
        add_layer(l, layers)
    end
    
    app.transaction(
        function()
        for i,frameNumber in ipairs(frameNumbers) do
            for i,l in ipairs(layers) do
                paste, metadata = doExecute(l, frameNumber)
                if paste then
                    local isVisible = app.activeLayer.isVisible
                    app.activeLayer.isVisible = true
                    app.command.Paste()
                    app.command.DeselectMask()
                    local cel = app.activeLayer:cel(frameNumber)
                    if cel ~= nil then
                        SetCelOffsetX(app.activeLayer:cel(frameNumber), metadata.offset_x, metadata.offset_y)
                    end
                    app.activeLayer.isVisible = isVisible
                end
            end
        end
    end)
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end