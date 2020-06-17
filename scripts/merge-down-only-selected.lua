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
    if layer.isImage and contains(exclude_layers, layer) then
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
    if layer.isImage and contains(exclude_layers, layer) then
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
    if layer.isImage and layer.isVisible and contains(excludes, layer) then
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

local function GetFirstImageLayer(layer)
    if layer.isImage then
        return layer
    end

    if #layer.layers > 0 then
        return GetFirstImageLayer(layer.layers[#layer.layers])
    end

    return nil
end

local function _GetNextImageLayer(layers, layer)
    if layer.stackIndex > 1 then
        return GetFirstImageLayer(layers[layer.stackIndex-1])
    elseif layer.stackIndex == 1 then
        if layer.parent.parent == nil then
            return nil
        end
        return _GetNextImageLayer(layer.parent.parent.layers, layer.parent)
    end

    return nil
end

local function GetNextImageLayer(layer)
    return _GetNextImageLayer(layer.parent.layers, layer)
end
-------------------------------------------------------------------------------
-- 共通ここまで
-------------------------------------------------------------------------------

function MergeDownOnlySelectedCels()
    local sprite = app.activeSprite
    local selected_layers = {}
    local selected_frames = {}
    local export_layer = nil
    for i,v in ipairs(app.range.layers) do
        if not contains(selected_layers, v) then
            selected_layers[#selected_layers+1] = v
        end
    end
    for i,v in ipairs(app.range.frames) do
        if not contains(selected_frames, v.frameNumber) then
            selected_frames[#selected_frames+1] = v.frameNumber
        end
    end

    if #selected_layers == 0 then
        return
    end
    -- 最初に追加されたレイヤー（一番下のレイヤー）の次のレイヤーを調べる
    export_layer = GetNextImageLayer(selected_layers[1])
    if export_layer == nil then
        return
    end

    if sprite.selection ~= nil then
        sprite.selection:deselect()
    end

    local unvisile_layers = SwitchVisibleAll(sprite, selected_layers)

    for i, v in pairs(selected_frames) do
        export_layer.isVisible = false
        app.activeFrame = v
        app.activeLayer = export_layer
        app.command.MaskAll()
        app.command.CopyMerged()

        export_layer.isVisible = true
        app.command.Paste()
        app.command.DeselectMask()
    end

    for i,l in ipairs(unvisile_layers) do
        l.isVisible = true
    end
end