
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

--- 引数layerに指定したレイヤのAlpha値が0以上の領域を選択する
local function SelectOnLayer(layer, frameNumber)
    local select = Selection()
    local cel = layer:cel(frameNumber)
    if cel ~= nil then
        select:add(MaskByColorOnCel(cel))
    end
    return select
end

--- 引数layersに指定したレイヤのAlpha値が0以上の領域を選択する
local function SelectOnLayers(layers, frameNumber)
    local select = Selection()
    for i, layer in ipairs(layers) do
        if layer.isImage then
            local cel = layer:cel(frameNumber)
            if cel ~= nil then
                select:add(MaskByColorOnCel(cel))
            end
        end
    end
    return select
end

--- (コピー元の)表示状態にするレイヤリストを取得する(excludeに含まれるレイヤは弾く)
local function _GetAllVisibleLayers(layer, exclude_layers, visible_layers)
    if not contains(exclude_layers, layer) then
        visible_layers[#visible_layers+1] = layer
    end
    if layer.isGroup and not contains(exclude_layers, layer) then
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            _GetAllVisibleLayers(l, exclude_layers, visible_layers)
        end
    end
end

--- include_layers配下の(コピー元の)表示状態にするレイヤリストを全て取得する(excludeに含まれるレイヤは弾く)
local function GetAllVisibleLayers(include_layers, exclude_layers)
    local visible_layers = {}
    for i, include_layer in ipairs(include_layers) do
        if not contains(visible_layers, include_layer) then
            -- 無駄な処理を行わないために
            -- 追加済み（検証済み）でない場合のみチェックする
            _GetAllVisibleLayers(include_layer, exclude_layers, visible_layers)
        end
    end
    return visible_layers
end

--- 不必要なレイヤを非表示状態にする(visible_layersに含まれるレイヤ以外を非表示)
--- 非表示にしたレイヤはunvisible_layersに格納される
local function _SetUnvisibleLayer(layer, visible_layers, unvisile_layers)
    if layer.isImage and layer.isVisible and not contains(visible_layers, layer) then
        unvisile_layers[#unvisile_layers+1] = layer
        layer.isVisible = false
    elseif layer.isGroup then
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            _SetUnvisibleLayer(l, visible_layers, unvisile_layers)
        end
    end
end

--- 不必要なレイヤを非表示状態にする(visible_layersに含まれるレイヤ以外を非表示)
--- 非表示にしたレイヤは戻り値で返却される（もともと非表示のレイヤは含まれない）
local function SetUnvisibleLayer(sprite, visible_layers)
      local unvisile_layers = {}
      for i,l in ipairs(sprite.layers) do
        _SetUnvisibleLayer(l, visible_layers, unvisile_layers)
      end
      return unvisile_layers
end

--- 指定のレイヤ・フレームにペーストする
function Paste(export_layer, frameNumber, metadata)
    --- ペーストの実行
    local isVisible = export_layer.isVisible
    export_layer.isVisible = true
    app.command.Paste()
    app.command.DeselectMask()
    local cel = export_layer:cel(frameNumber)
    if cel ~= nil then
        SetCelOffsetX(cel, metadata.offset_x, metadata.offset_y)
    end
    export_layer.isVisible = isVisible
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

--- 指定されたレイヤを表示状態にする
function ResetVisibleLayers(unvisile_layers)
    for i,l in ipairs(unvisile_layers) do
        l.isVisible = true
    end
end

--- metadata1とmetadata2のコピー元が同一かチェック
local function check_sametarget(metadata1, metadata2)
    if metadata1.command ~= metadata2.command then return false end
    if not same_array(metadata1.export_names, metadata2.export_names) then return false end
    if not same_array(metadata1.include_names, metadata2.include_names) then return false end
    if not same_array(metadata1.exclude_names, metadata2.exclude_names) then return false end
    return false
end
-------------------------------------------------------------------------------
-- 共通ここまで
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- メイン処理
--
-------------------------------------------------------------------------------

local function SaveOffset(layer, frameNumbers)
    local prev_metadata = nil
    local command = nil
    local visible_layers = {}

    local export_layer = nil

    for i, frameNumber in ipairs(frameNumbers) do
        local metadata = GetMetaData(layer, frameNumber)
        if metadata == nil then goto loopend end

        -- 前フレームと処理対象が異なる場合、表示・非表示の切り替え等を行う
        -- セルに設定が保存されている場合のみ該当
        if prev_metadata == nil or not check_sametarget(prev_metadata, metadata) then
            command = RestoreMetaData(layer.sprite, layer, metadata)
            -- 表示対象レイヤの取得
            visible_layers = GetAllVisibleLayers(command.include_layers, command.exclude_layers)
            export_layer = command.export_layer
        end
        
        -- チェック先のセルを取得
        local cel = export_layer:cel(frameNumber)
        if cel == nil then goto loopend end

        -- 領域を選択
        app.command.DeselectMask()
        local select = SelectOnLayers(visible_layers)
        
        local offset_x, offset_y = GetCelOffset(cel, select)
        metadata.offset_x = offset_x
        metadata.offset_y = offset_y
        metadata.ver = "v2"

        cel = layer:cel(frameNumber)
        if cel == nil then
            cel = app.activeSprite:newCel(layer, frameNumber)
        end
        SetCelMetaData(cel, metadata)
        ::loopend::
    end
end

local function doCommand(layer, frameNumbers)
    local prev_metadata = nil
    local command = nil
    local visible_layers = {}
    local unvisile_layers = {}

    local export_layer = nil
    local command_type = "none"

    for i, frameNumber in ipairs(frameNumbers) do
        local metadata = GetMetaData(layer, frameNumber)
        if metadata == nil then goto loopend end

        -- 前フレームと処理対象が異なる場合、表示・非表示の切り替え等を行う
        -- セルに設定が保存されている場合のみ該当
        if prev_metadata == nil or not check_sametarget(prev_metadata, metadata) then
            command = RestoreMetaData(layer.sprite, layer, metadata)
            -- 非表示レイヤを元に戻す
            ResetVisibleLayers(unvisile_layers)
            -- 表示対象レイヤの取得
            visible_layers = GetAllVisibleLayers(command.include_layers, command.exclude_layers)
            -- 不必要なレイヤの非表示
            unvisile_layers = SetUnvisibleLayer(layer.sprite, visible_layers)
            command_type = command.command
            export_layer = command.export_layer
        end

        if command_type == "merge" then
            -- コピー領域の選択
            app.command.DeselectMask()
            app.command.MaskAll()
    
            -- export_layerに移動
            app.activeFrame = export_layer.sprite.frames[frameNumber]
            app.activeLayer = export_layer
            app.command.ClearCel()
    
            -- コピー
            app.command.CopyMerged()
    
            -- ペースト
            Paste(export_layer, frameNumber, metadata)
        end
    
        if command_type == "outline" then
            -- export_layerに移動
            app.activeFrame = export_layer.sprite.frames[frameNumber]
            app.activeLayer = export_layer
            app.command.ClearCel()
    
            -- 領域を選択
            local select = SelectOnLayers(visible_layers)
            layer.sprite.selection:add(select)
            app.command.ModifySelection{ modifier="expand", quantity=1, brush="circle" }
    
            -- 塗りつぶし
            app.command.Fill()
            app.command.DeselectMask()
        end
    
        if command_type == "mask" or command == "imask" then
            -- コピー領域の選択
            app.command.DeselectMask()
            local select = SelectOnLayer(layer)
    
            layer.sprite.selection:add(select)
    
            if command == "imask" then
                app.command.InvertMask()
            end
    
            -- export_layerに移動
            app.activeFrame = export_layer.sprite.frames[frameNumber]
            app.activeLayer = export_layer
            app.command.ClearCel()
    
            -- コピー
            app.command.CopyMerged()
            app.command.DeselectMask()
    
            -- ペースト
            Paste(export_layer, frameNumber, metadata)
        end
    
        ::loopend::
    end
    -- 非表示レイヤを元に戻す
    ResetVisibleLayers(unvisile_layers)
end

function SelectTargetLayer()
    local frameNumber = app.range.frames[1].frameNumber
    local layer = app.range.layers[1]
    local metadata, command = RestoreCommandData(layer, frameNumber)
    if command == nil then
        return false
    end
    app.command.DeselectMask()
    -- 表示対象レイヤの取得
    local visible_layers = GetAllVisibleLayers(command.include_layers, command.exclude_layers)
    -- 領域を選択
    local select = SelectOnLayers(visible_layers)
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
            for i,layer in ipairs(layers) do
                SaveOffset(layer,frameNumbers)
            end
        end
    )
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end

function AutoMerge()
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
            for i,layer in ipairs(layers) do
                doCommand(layer, frameNumbers)
            end
        end
    )

    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end