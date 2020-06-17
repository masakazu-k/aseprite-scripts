
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
    local _select = Selection()
    for i = 1, #points do
      local p = points[i]
      local r = Rectangle(p.x, p.y, 1 ,1)
      -- マスク対象エリアを選択
      _select:add(Selection(r))
    end
    cel.sprite.selection:add(_select)
end

local function MaskByColorOnLayer(layer, frameNumber, selected_layers, exclude_layers)
    -- app.alert(layer.name)
    if layer.isImage and not contains(exclude_layers, layer) then
        -- MaskByColorOnCel(layer, frameNumber)
        MaskByColorOnCel(layer:cel(frameNumber))
        selected_layers[#selected_layers+1] = layer
    elseif layer.isGroup then
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            MaskByColorOnLayer(l, frameNumber, selected_layers, exclude_layers)
        end
    end
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
    -- app.command.MaskByColor()
    for i=1, #layers do
        local layer = layers[i]
        if layer.isVisible then
            MaskByColorOnLayer(layer, frameNumber, selected_layers, exclude_layers)
        end
    end
    return selected_layers
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
-------------------------------------------------------------------------------
-- 共通ここまで
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- メイン処理
--
-------------------------------------------------------------------------------

local function  doExecute(layer, frameNumber)

    local command, include_layers, exclude_layers, export_layer = GetCommandData(layer, frameNumber)
    
    if command == nil then
        return
    end

    if command == "merge" then
        if app.activeSprite.selection ~= nil then
            app.activeSprite.selection:deselect()
        end

        local selected_layers = MaskByColorOnLayers(include_layers, frameNumber, exclude_layers)
        local unvisile_layers = SwitchVisibleAll(layer.sprite, selected_layers)

        if app.activeSprite.selection.isEmpty then
            for i,l in ipairs(unvisile_layers) do
                l.isVisible = true
            end
            return false
        end

        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.command.ClearCel()
        app.command.CopyMerged()
    
        for i,l in ipairs(unvisile_layers) do
            l.isVisible = true
        end
        return true
    end

    if command == "outline" then
        if app.activeSprite.selection ~= nil then
            app.activeSprite.selection:deselect()
        end
        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer

        MaskByColorOnLayers(include_layers, frameNumber, exclude_layers)
        app.command.ModifySelection{ modifier="expand", quantity=1, brush="circle" }

        app.command.ClearCel()
        app.command.Fill()

        app.activeSprite.selection:deselect()
        return false
    end

    if command == "mask" or command == "imask" then
        if app.activeSprite.selection ~= nil then
            app.activeSprite.selection:deselect()
        end

        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.activeSprite.selection:deselect()

        MaskByColorOnLayer(layer, frameNumber, {}, exclude_layers)
        local selected_layers = GetAllMaskTargetList(include_layers, frameNumber, exclude_layers)
        local unvisile_layers = SwitchVisibleAll(layer.sprite, selected_layers)
        if command == "imask" then
            app.command.InvertMask()
        end
        if app.activeSprite.selection.isEmpty then
            for i,l in ipairs(unvisile_layers) do
                l.isVisible = true
            end
            return false
        end

        app.command.CopyMerged()
        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.command.ClearCel()
    
        for i,l in ipairs(unvisile_layers) do
            l.isVisible = true
        end
        app.activeSprite.selection:deselect()

        return true
    end

end

function SelectTargetLayer()
    local frameNumber = app.range.frames[1].frameNumber
    local layer = app.range.layers[1]
    local command, include_layers, exclude_layers, export_layer = RestoreLayerMetaData(layer)
    if command == nil then
        return false
    end
    if app.activeSprite.selection ~= nil then
        app.activeSprite.selection:deselect()
    end

    MaskByColorOnLayers(include_layers, frameNumber, exclude_layers)
end

local function add_layer(layer, layers)
    if layer.isGroup then
        for i,l in ipairs(layer.layers) do
            add_layer(l, layers)
        end
    end
    layers[#layers+1] = layer
end

function AutoMerge()
    local paste = false
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
                paste = doExecute(l, frameNumber)
                if paste then
                    local isVisible = app.activeLayer.isVisible
                    app.activeLayer.isVisible = true
                    app.command.Paste()
                    app.command.DeselectMask()
                    app.activeLayer.isVisible = isVisible
                end
            end
        end
    end)
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end