
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
        return Selection()
    end
    local select = Selection()
    for i = 1, #points do
      local p = points[i]
      local r = Rectangle(p.x, p.y, 1, 1)
      -- マスク対象エリアを選択
      select:add(Selection(r))
    end
    return select
end

--- 引数layerに指定したレイヤのAlpha値が0以上の領域を取得する
local function SelectOnLayer(layer, frameNumber)
    local cel = layer:cel(frameNumber)
    if cel ~= nil then
        return MaskByColorOnCel(cel)
    end
    -- celがない場合、空の領域を返却
    local select = Selection()
    return select
end

--- 引数layersに指定したレイヤのAlpha値が0以上の領域を取得する（Groupレイヤは無視）
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

--- (コピー元の)表示状態にするレイヤリストを取得する(exclude_layersに含まれるレイヤは無視)
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

--- include_layers配下の(コピー元の)表示状態にするレイヤリストを全て取得する(exclude_layersに含まれるレイヤは無視)
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
    if layer.isVisible then
        if layer.isImage and not contains(visible_layers, layer) then
            unvisile_layers[#unvisile_layers+1] = layer
            layer.isVisible = false
        elseif layer.isGroup then
            -- グループ配下の全レイヤーを処理
            for i,l in ipairs(layer.layers) do
                _SetUnvisibleLayer(l, visible_layers, unvisile_layers)
            end
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

--- 指定レイヤを親まで遡って強制的に表示状態にする
local function _ForceVisibleLayer(layer, sprite, visible_layers, force_visible_layers)
    if not layer.isVisible then
        force_visible_layers[#force_visible_layers+1] = layer
        layer.isVisible = true
    end
    if layer.parent ~= nil then
        -- 親がSpriteの場合、例外が発生するのでそこで処理を中断する
        -- ホントはSpriteを判断したいけど、なんか失敗するから一旦この方法をとる
        -- _ForceVisibleLayer(layer.parent, sprite, visible_layers, force_visible_layers)
        pcall(_ForceVisibleLayer, layer.parent, sprite, visible_layers, force_visible_layers)
    end
end

--- 指定レイヤを親まで遡って強制的に表示状態にする
--- 表示状態に変更したレイヤは戻り値で返却される（もともと表示状態のレイヤは含まれない）
local function ForceVisibleLayer(sprite, visible_layers)
    local force_visible_layers = {}
    for i,l in ipairs(visible_layers) do
        _ForceVisibleLayer(l, sprite, visible_layers, force_visible_layers)
    end
    return force_visible_layers
end

--- 指定のレイヤ・フレームにペーストする
function Paste(export_layer, frameNumber, metadata)
    --- ペーストの実行
    local isVisible = export_layer.isVisible
    export_layer.isVisible = true
    local cel = export_layer:cel(frameNumber)
    local cel_metadata = nil
    if cel ~= nil then
        cel_metadata = GetCelMetaData(cel)
    end
    app.command.ClearCel()
    app.command.Paste()
    app.command.DeselectMask()
    cel = export_layer:cel(frameNumber)
    if cel ~= nil then
        if cel_metadata == nil then
            cel_metadata = CreateExportCelMetaData(metadata.label)
            cel_metadata.offset_x = metadata.offset_x
            cel_metadata.offset_y = metadata.offset_y
        end
        if cel_metadata.offset_x ~= 0 or cel_metadata.offset_y ~= 0 then
            SetCelMetaData(cel, cel_metadata)
            SetCelOffsetX(cel, cel_metadata.offset_x, cel_metadata.offset_y)
        else
            SetCelMetaData(cel, nil)
        end
    else
        -- コピー結果が空画像の場合、celはnilになる
        if cel_metadata ~= nil
        and (cel_metadata.offset_x ~= 0 or cel_metadata.offset_y ~= 0) then
            -- オフセット情報が消えてしまわないように、元に戻す
            export_layer.sprite:newCel(export_layer, frameNumber)
            cel = export_layer:cel(frameNumber)
            SetCelMetaData(cel, cel_metadata)
        end
    end
    export_layer.isVisible = isVisible
end

function Fill(layer, frameNumber, metadata)
    --- ペーストの実行
    local isVisible = layer.isVisible
    layer.isVisible = true
    app.command.ClearCel()
    app.command.Fill()
    layer.isVisible = isVisible
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

--- 指定されたレイヤを非表示状態にする
function ResetUnVisibleLayers(visile_layers)
    for i,l in ipairs(visile_layers) do
        l.isVisible = false
    end
end

--- metadata1とmetadata2のコピー元が同一かチェック
local function check_sametarget(metadata1, metadata2)
    if metadata1.command ~= metadata2.command then return false end
    if not same_array(metadata1.export_names, metadata2.export_names) then return false end
    if not same_array(metadata1.include_names, metadata2.include_names) then return false end
    if not same_array(metadata1.exclude_names, metadata2.exclude_names) then return false end
    return true
end

--- セルがロックされているかチェック
local function is_locked_cel(metadata)
    if metadata.locked == nil then
        return false
    end
    return metadata.locked
end

--- select1 と select2の共通部分を新しいSelectionとして取得する
local function get_intersection(select1, select2)
    if select1.isEmpty or select2.isEmpty then
        return Selection()
    end

    local new_select = Selection()
    local start_x, end_x = select1.bounds.x, select1.bounds.x + select1.bounds.width
    local start_y, end_y = select1.bounds.y, select1.bounds.y + select1.bounds.height
    for x=start_x,end_x do
        for y=start_y,end_y do
            if select1:contains(x,y) and select2:contains(x,y) then
                new_select:add(Selection(Rectangle(x,y, 1, 1)))
            end
        end
    end
    return new_select
end

local function get_inv_intersection(select1, select2)
    if select1.isEmpty or select2.isEmpty then
        return Selection()
    end

    local new_select = Selection()
    local start_x, end_x = select1.bounds.x, select1.bounds.x + select1.bounds.width
    local start_y, end_y = select1.bounds.y, select1.bounds.y + select1.bounds.height
    for x=start_x,end_x do
        for y=start_y,end_y do
            if not select1:contains(x,y) or not select2:contains(x,y) then
                new_select:add(Selection(Rectangle(x,y, 1, 1)))
            end
        end
    end
    return new_select
end
--- src と dst を比較して、削除された領域を新しいSelectionとして取得する
local function get_delete_area(src, dst)
    if src.isEmpty or dst.isEmpty then
        return Selection()
    end

    local new_select = Selection()
    local start_x, end_x = src.bounds.x, src.bounds.x + src.bounds.width
    local start_y, end_y = src.bounds.y, src.bounds.y + src.bounds.height
    for x=start_x,end_x do
        for y=start_y,end_y do
            if src:contains(x,y) and not dst:contains(x,y) then
                new_select:add(Selection(Rectangle(x,y, 1, 1)))
            end
        end
    end
    return new_select
end

-------------------------------------------------------------------------------
-- 共通ここまで
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-- メイン処理
--
-------------------------------------------------------------------------------

--- Exportレイヤの状態からマスク画像を生成する
local function CreateAutoMask(layer, frameNumbers)
    local prev_metadata = nil
    local command = nil
    local visible_layers = {}
    local export_layer = layer
    local export_metadata = GetLayerMetaData(layer)
    -- メタデータがないレイヤはスキップ
    if export_metadata == nil then return end
    -- Export Layer以外はスキップ
    if export_metadata.mt ~= METADATA_TYPE.EXPORT_LAYER then return end

    -- 関連するマスクレイヤを探す
    local mask_layer = SearchMaskLayerByLabel(app.activeSprite, export_metadata.label)
    if mask_layer == nil then return end
    
    for i, frameNumber in ipairs(frameNumbers) do
        local metadata = GetMetaData(mask_layer, frameNumber)
        -- メタデータがないフレームはスキップ
        if metadata == nil then goto loopend end

        local export_cel = export_layer:cel(frameNumber)
        if export_cel == nil then goto loopend end

        -- エクスポート先の色がある領域を取得
        local export_select = MaskByColorOnCel(export_cel)
        local export_cel_metadata = GetCelMetaData(export_cel)
        if export_select.isEmpty then goto loopend end
        
        if export_cel_metadata ~= nil then
            -- オフセットの分だけ元にずらす
            export_select.origin = Point{
                x = export_select.origin.x + export_cel_metadata.offset_x,
                y = export_select.origin.y + export_cel_metadata.offset_y
            }
        end
        
        -- 表示対象レイヤの取得
        -- 前フレームと処理対象が異なる場合、表示対象レイヤの取得を行う
        if prev_metadata == nil or not check_sametarget(prev_metadata, metadata) then
            command = RestoreMetaData(layer.sprite, layer, metadata)
            -- 表示対象レイヤの取得
            visible_layers = GetAllVisibleLayers(command.include_layers, command.exclude_layers)
            export_layer = command.export_layer
        end
        
        -- Visible Layer（コピー元）の色がある領域を取得
        local include_select = SelectOnLayers(visible_layers, frameNumber)
        if include_select.isEmpty then goto loopend end

        -- 削除された領域のマスクを取得
        local intersection_select = get_delete_area(include_select, export_select)
        if intersection_select.isEmpty then goto loopend end

        -- フォーカスを変える
        app.activeFrame = mask_layer.sprite.frames[frameNumber]
        app.activeLayer = mask_layer

        -- 塗りつぶし
        layer.sprite.selection:add(intersection_select)
        Fill(mask_layer, frameNumber, metadata)
        app.command.DeselectMask()
        if metadata.command ~= COMMAND_TYPE.INVERSE_MASK then
            metadata.command = COMMAND_TYPE.INVERSE_MASK
            metadata.inherit = false
        end
        SetCelMetaData(mask_layer:cel(frameNumber), metadata)
        prev_metadata = metadata
        ::loopend::
    end
end

function StoreMergeOffsetCels(layer, frameNumbers)
    local prev_metadata = nil
    local command = nil
    local visible_layers = {}

    local export_layer = nil
    local export_metadata = GetLayerMetaData(layer)
    -- メタデータがないレイヤはスキップ
    if export_metadata == nil then return end
    -- Export Layer以外はスキップ
    if export_metadata.mt ~= METADATA_TYPE.EXPORT_LAYER then return end

    -- 関連するマスクレイヤを探す
    local mask_layer = SearchMaskLayerByLabel(app.activeSprite, export_metadata.label)
    -- マスクレイヤがないレイヤはスキップ
    if mask_layer == nil then return end

    for i, frameNumber in ipairs(frameNumbers) do
        local metadata = GetMetaData(mask_layer, frameNumber)
        -- メタデータがないフレームはスキップ
        if metadata == nil then goto loopend end

        -- 前フレームと処理対象が異なる場合、表示・非表示の切り替え等を行う
        -- セルに設定が保存されている場合のみ該当
        if prev_metadata == nil or not check_sametarget(prev_metadata, metadata) then
            command = RestoreMetaData(layer.sprite, layer, metadata)
            -- 表示対象レイヤの取得
            visible_layers = GetAllVisibleLayers(command.include_layers, command.exclude_layers)
            export_layer = command.export_layer
        end
        
        -- Export Layerのセルを取得
        local cel = export_layer:cel(frameNumber)
        -- Export Layerにcelがない場合、オフセットを取得できないのでスキップ
        if cel == nil then goto loopend end

        -- Visible Layer（コピー元）の色がある領域を取得
        local select = SelectOnLayers(visible_layers, frameNumber)
        
        if command.command == COMMAND_TYPE.MASK then
            local mask_area = SelectOnLayer(mask_layer, frameNumber)
            select = get_intersection(select, mask_area)
        elseif command.command == COMMAND_TYPE.INVERSE_MASK then
            local mask_area = SelectOnLayer(mask_layer, frameNumber)
            select = get_delete_area(select, mask_area)
        end

        -- オフセットを取得
        local offset_x, offset_y = GetCelOffset(cel, select)

        if offset_x~=0 or offset_y~=0 then
            -- セルのメタデータを取得・更新
            local cel_metadata = GetCelMetaData(cel)
            if cel_metadata == nil then
                cel_metadata = CreateExportCelMetaData(metadata.label)
            end
            cel_metadata.offset_x = offset_x
            cel_metadata.offset_y = offset_y
            SetCelMetaData(cel, cel_metadata)
        else 
            -- オフセットがない場合、リセットする
            SetCelMetaData(cel, nil)
        end
        prev_metadata = metadata
        ::loopend::
    end
end

function DoMergeCommand(layer, frameNumbers)
    local prev_metadata = nil
    local command = nil
    local visible_layers = {}
    local unvisile_layers = {}
    local force_visible_layers = {}

    local export_layer = nil
    local export_metadata = GetLayerMetaData(layer)
    -- メタデータがないレイヤはスキップ
    if export_metadata == nil then return end
    -- Export Layer以外はスキップ
    if export_metadata.mt ~= METADATA_TYPE.EXPORT_LAYER then return end

    -- 関連するマスクレイヤを探す
    local mask_layer = SearchMaskLayerByLabel(app.activeSprite, export_metadata.label)
    -- マスクレイヤがないレイヤはスキップ
    if mask_layer == nil then return end
    local command_type = "none"

    for i, frameNumber in ipairs(frameNumbers) do
        local metadata = GetMetaData(mask_layer, frameNumber)
        -- メタデータがないセルはスキップ
        if metadata == nil then goto loopend end
        -- ロックされているセルはスキップ
        if is_locked_cel(metadata) then goto loopend end

        -- 前フレームと処理対象が異なる場合、表示・非表示の切り替え等を行う
        -- セルに設定が保存されている場合のみ該当
        if prev_metadata == nil or not check_sametarget(prev_metadata, metadata) then
            command = RestoreMetaData(layer.sprite, mask_layer, metadata)
            -- 表示レイヤを元に戻す
            -- ResetUnVisibleLayers(force_visible_layers)
            -- 非表示レイヤを元に戻す
            ResetVisibleLayers(unvisile_layers)
            -- 表示対象レイヤの取得
            visible_layers = GetAllVisibleLayers(command.include_layers, command.exclude_layers)
            -- 不必要なレイヤの非表示
            unvisile_layers = SetUnvisibleLayer(layer.sprite, visible_layers)
            -- 特殊レイヤを非表示
            for i,exclude_layer in ipairs(command.exclude_layers) do
                if exclude_layer.isGroup and exclude_layer.isVisible then
                    unvisile_layers[#unvisile_layers+1] = exclude_layer
                    exclude_layer.isVisible = false
                end
            end
            -- コピー対象の内、直接指定されたレイヤを強制表示
            -- force_visible_layers = ForceVisibleLayer(layer.sprite, command.include_layers)

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
            local select = SelectOnLayers(visible_layers, frameNumber)
            export_layer.sprite.selection:add(select)
            app.command.ModifySelection{ modifier="expand", quantity=1, brush="circle" }
    
            -- 塗りつぶし
            app.command.Fill()
            app.command.DeselectMask()
        end
    
        if command_type == "mask" or command_type == "imask" then
            -- コピー領域の選択
            app.command.DeselectMask()
            local select = SelectOnLayer(mask_layer, frameNumber)
    
    
            if command_type == "imask" then
                if select.isEmpty then
                    app.command.MaskAll()
                else
                    export_layer.sprite.selection:add(select)
                    app.command.InvertMask()
                end
            else
                export_layer.sprite.selection:add(select)
            end

            -- コピー対象が無ければ処理終了
            if export_layer.sprite.selection.isEmpty then goto loopend end
    
            -- export_layerに移動
            app.activeFrame = export_layer.sprite.frames[frameNumber]
            app.activeLayer = export_layer
    
            -- コピー
            app.command.CopyMerged()
            app.command.DeselectMask()
    
            -- ペースト
            Paste(export_layer, frameNumber, metadata)
        end
        prev_metadata = metadata
        ::loopend::
    end
    -- 表示レイヤを元に戻す
    -- ResetUnVisibleLayers(force_visible_layers)
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
    local select = SelectOnLayers(visible_layers, frameNumber)
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

--- 処理対象のフレームとレイヤを取得する
local function GetTargetLayerAndFrameNumbers()
    local frameNumbers = {}
    local layers = {}
    if app.range.type == RangeType.LAYERS then
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

function LockUnlockCels()
    local layers, frameNumbers = GetTargetLayerAndFrameNumbers()
    
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    app.transaction(
        function()
            for i,layer in ipairs(layers) do
                for j,frameNumber in ipairs(frameNumbers) do
                    local cel = layer:cel(frameNumber)
                    if cel ~= nil then
                        local metadata = GetMetaData(layer, frameNumber)
                        metadata.ver = "v2"
                        if metadata.locked == nil or metadata.locked == false then
                            metadata.locked = true
                        else
                            metadata.locked = false
                        end
                        SetCelMetaData(cel, metadata)
                    end
                end
            end
        end
    )
    CacheReset()
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end

function CreateMaskCels()
    local layers, frameNumbers = GetTargetLayerAndFrameNumbers()
    
    local oldActiveFrame = app.activeFrame
    local oldActiveLayer = app.activeLayer
    app.transaction(
        function()
            for i,layer in ipairs(layers) do
                CreateAutoMask(layer, frameNumbers)
            end
        end
    )
    CacheReset()
    app.activeFrame = oldActiveFrame
    app.activeLayer = oldActiveLayer
    app.refresh()
end