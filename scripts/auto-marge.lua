
-------------------------------------------------------------------------------
-- 共通ここから
-------------------------------------------------------------------------------
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


--- レイヤーを検索する
local function search_layer(layers, name, target_layers)
    for i, layer in ipairs(layers) do
        if layer.name == name then
            target_layers[#target_layers+1] = layer
        end
        if layer.isGroup then
            search_layer(layer.layers, name, target_layers)
        end
    end
end

  local function  search(array, item)
    if array == nil then
        return true
    end
    for i,_item in ipairs(array) do
        if _item == item then
            return false
        end
    end
    return true
end
  
-- local function MaskByColorOnCel(layer, frameNumber)
--     local oldLayer = app.activeLayer
--     local oldFrame = app.activeFrame
--     local oldSelection = Selection(layer.sprite.selection)

--     -- マスク対象エリアを選択
--     app.activeLayer = layer
--     app.activeFrame = layer.sprite.frames[frameNumber]
--     app.command.MaskContent()
--     layer.sprite.selection:add(oldSelection)

--     app.activeLayer = oldLayer
--     app.activeFrame = oldFrame
-- end

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
    if layer.isImage and search(exclude_layers, layer) then
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

local function GetMaskTargetList(layer, frameNumber, target_layers, exclude_layers)
    if layer.isImage and search(exclude_layers, layer) then
        target_layers[#target_layers+1] = layer
    elseif layer.isGroup then
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            GetMaskTargetList(l, frameNumber, target_layers, exclude_layers)
        end
    end
end

local function GetAllMaskTargetList(layers, frameNumber, exclude_layers)
    local target_layers = {}
    for i=1, #layers do
        local layer = layers[i]
        if layer.isVisible then
            GetMaskTargetList(layer, frameNumber, target_layers, exclude_layers)
        end
    end
    return target_layers
    
end
  local function SwitchVisible(layer, excludes, layers)
    if layer.isImage and layer.isVisible and search(excludes, layer) then
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
-- データ取得系ここから
-------------------------------------------------------------------------------
local function get_target_data(layer, strdata)
    local exclude_names = {}
    local layer_names = {}
    -- マスク対象等のレイヤを調べる
    local layer_types = split(strdata, ":")
    if #layer_types == 2 then
        layer_names = split(layer_types[1], ",")
        exclude_names = split(layer_types[2], ",")
    else
        layer_names = split(strdata, ",")
    end
    local target_layers = {}
    for i, name in pairs(layer_names) do
        search_layer(layer.sprite.layers, name, target_layers)
    end
    local exclude_layers = {}
    for i, name in pairs(exclude_names) do
        search_layer(layer.sprite.layers, name, exclude_layers)
    end
    return target_layers, exclude_layers
end

local function get_export_data(layer, strdata)
    -- マスク対象等のレイヤを調べる
    local layer_types = split(strdata, ":")
    if #layer_types == 2 then
        local export_layers = {}
        local command = layer_types[1]
        local export_names = split(layer_types[2], ",")
        for i, name in pairs(export_names) do
            search_layer(layer.sprite.layers, name, export_layers)
        end

        if #export_layers > 0 then
            return command, export_layers[1]
        else
            return command, layer
        end
    else
        return strdata, layer
    end
end

local function get_meta_data(layer)
    local sp_layer_name = split(layer.name, "=")
    if #sp_layer_name == 2 then
        local command, export_layer = get_export_data(layer, sp_layer_name[1])
        local target_layers , exclude_layers = get_target_data(layer, sp_layer_name[2])
        return command, target_layers, exclude_layers, export_layer
    end
    return nil, nil, nil
end
-------------------------------------------------------------------------------
-- データ取得系ここまで
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- メイン処理
--
-------------------------------------------------------------------------------

local function  doExecute(layer, frameNumber)

    local command, target_layers, exclude_layers, export_layer = get_meta_data(layer)
    
    if command == nil then
        return
    end

    if command == "marge" then
        if app.activeSprite.selection ~= nil then
            app.activeSprite.selection:deselect()
        end

        local selected_layers = MaskByColorOnLayers(target_layers, frameNumber, exclude_layers)
        local unvisile_layers = SwitchVisibleAll(layer.sprite, selected_layers)

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

        MaskByColorOnLayers(target_layers, frameNumber, exclude_layers)
        app.command.ModifySelection{ modifier="expand", quantity=1, brush="circle" }

        app.command.ClearCel()
        app.command.Fill()

        app.activeSprite.selection:deselect()
        return false
    end

    if command == "mask" then
        if app.activeSprite.selection ~= nil then
            app.activeSprite.selection:deselect()
        end

        app.activeFrame = export_layer.sprite.frames[frameNumber]
        app.activeLayer = export_layer
        app.activeSprite.selection:deselect()

        MaskByColorOnLayer(layer, frameNumber, {}, exclude_layers)
        local selected_layers = GetAllMaskTargetList(target_layers, frameNumber, exclude_layers)
        local unvisile_layers = SwitchVisibleAll(layer.sprite, selected_layers)
        
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

local function add_layer(layer, layers)
    if layer.isGroup then
        for i,l in ipairs(layer.layers) do
            add_layer(l, layers)
        end
    end
    layers[#layers+1] = layer
end

function AutoMarge()
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
    
    for i,frameNumber in ipairs(frameNumbers) do
        for i,l in ipairs(layers) do
            app.transaction(
                function()
                    paste = doExecute(l, frameNumber)
            end)
            if paste then
                app.transaction(
                    function()
                        app.command.Paste()
                        app.command.DeselectMask()
                end)
            end
        end
    end
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end