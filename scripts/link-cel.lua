

local function CopyImageFromCel(srcCel, dstCel, metadata)
    --- イメージをコピーする
    dstCel.image = Image(srcCel.image)
    --- イメージにオフセットを適用する
    local p = Point{
        x = srcCel.position.x - metadata.offset_x,
        y = srcCel.position.y - metadata.offset_y
    }
    dstCel.position = p
end

--- 指定のセルをソースセルに設定する
local function SetSrcCel(srcCel)
    local metadata = GetCelMetaData(srcCel)
    if metadata == nil then
        -- デフォルト
        metadata = CreateLinkMetaData()
    else
        if metadata.mt ~= METADATA_TYPE.LINK_CEL then
            return false
        end
        metadata = CreateLinkMetaData()
    end
    metadata.is_src = true
    SetCelMetaData(srcCel, metadata)
    return true
end

--- 指定のセルをDstCelに設定してリンクを解除する
--- @return boolean DstCelを設定できた場合:true
local function SetDstCelAndUnLink(cel, frameNumbers)
    local metadata = GetCelMetaData(cel)
    if metadata == nil then
        -- リンクがないセルはDstCelにしない（できない）
        local linkedFrameNumbers = SearchLinkedCels(cel.layer, cel.frame.frameNumber)
        if #linkedFrameNumbers <= 1 then return false end
        if frameNumbers ~= nil then
            local newLinkedFrameNumbers = intersect(linkedFrameNumbers, frameNumbers)
            -- 選択範囲外にちゃんとSrcCelが存在するか確認する
            -- 存在しない場合、DstCelに設定しない
            if #newLinkedFrameNumbers == #linkedFrameNumbers then
                return false
            end
        end

        -- リンク先セルをSRCセルに設定する
        metadata = CreateLinkMetaData()
        metadata.is_src = true
        SetCelMetaData(cel, metadata)
    else
        if metadata.mt == METADATA_TYPE.LINK_CEL and not metadata.is_src then
            -- DstCelの場合
            -- もうすでにDstCelの場合は何もしない
            return false
        elseif metadata.mt == METADATA_TYPE.LINK_CEL and metadata.is_src then
            -- SrcCelの場合
            -- リンクがないセルはDstCelにしない（できない）
            local linkedFrameNumbers = SearchLinkedCels(cel.layer, cel.frame.frameNumber)
            if #linkedFrameNumbers <= 1 then return false end
            if frameNumbers ~= nil then
                local newLinkedFrameNumbers = intersect(linkedFrameNumbers, frameNumbers)
                -- 選択範囲外にちゃんとSrcCelが存在するか確認する
                -- 存在しない場合、DstCelに設定しない
                if #newLinkedFrameNumbers == #linkedFrameNumbers then
                    return false
                end
            end
        else
            -- 別のメタデータがある場合も何もしない
            return false
        end
    end
    -- 既存のセルを削除したら消える事があるのでバックアップ
    local image = Image(cel.image)
    local position = cel.position

    -- 新しいセルを作成しリンクを切る
    local dstCel = app.activeSprite:newCel(cel.layer, cel.frame.frameNumber)
    dstCel.image = image
    dstCel.position = position

    -- DstCelに設定する
    metadata.is_src = false
    SetCelMetaData(dstCel, metadata)
    return true
end

--- 指定のセルをディストセルに設定してリンクを解除する
function SetDstCelsAndUnLink(layer, frameNumbers)
    for j,frameNumber in ipairs(frameNumbers) do
        local cel = layer:cel(frameNumber)
        if cel ~= nil then
            SetDstCelAndUnLink(cel)
        end
    end
end

--- aseprite標準のリンク情報を残して、そこだけ分離する
--- （リンク済みセルリストの内、選択範囲内のセルだけリンクし直す）
local function SetDstCel(cel, frameNumbers)
    local linkedFrameNumbers = SearchLinkedCels(cel.layer, cel.frame.frameNumber)
    local newLinkedFrameNumbers = intersect(linkedFrameNumbers, frameNumbers)
    -- 選択範囲外にちゃんとSrcCelが存在するか確認する
    -- 存在しない場合、DstCelに設定しない
    if #newLinkedFrameNumbers == #linkedFrameNumbers then
        return false
    end

    --- SetDstCelAndUnLink後はセルの情報がリセットされるので退避させる
    local layer = cel.layer

    if SetDstCelAndUnLink(cel) then
        LinkCels(layer, newLinkedFrameNumbers)
    end
    return true
end

--- 指定のセルをDstCelに設定する
function SetDstCels(layer, frameNumbers)
    for j,frameNumber in ipairs(frameNumbers) do
        local cel = layer:cel(frameNumber)
        if cel ~= nil then
            SetDstCel(cel, frameNumbers)
        end
    end
end

function SetSrcCels(layer, dstFrameNumbers, srcFrameNumbers)
end

--- ソースセルと原点を比較しオフセットを取得する
function GetCelOffsetFromSrcCel(srcCel, dstCel)
    return srcCel.position.x - dstCel.position.x, srcCel.position.y - dstCel.position.y
end

local function CopyFromSrcCel(dstCel, frameNumbers)
    local metadata = GetCelMetaData(dstCel)
    if metadata == nil or metadata.mt ~= METADATA_TYPE.LINK_CEL then return end
    if metadata.is_src then return end

    local srcCel = SearchSrcCelByLabel(app.activeSprite, metadata.label)
    if srcCel == nil then return end

    CopyImageFromCel(srcCel, dstCel, metadata)
end

function CopyFromSrcCels(layer, frameNumbers)
    for j,frameNumber in ipairs(frameNumbers) do
        local cel = layer:cel(frameNumber)
        if cel ~= nil then
            CopyFromSrcCel(cel, frameNumbers)
        end
    end
end

local function StoreOffsetFromSrcCel(dstCel, frameNumbers)
    local metadata = GetCelMetaData(dstCel)
    if metadata == nil or metadata.mt ~= METADATA_TYPE.LINK_CEL then return end
    if metadata.is_src then return end

    local srcCel = SearchSrcCelByLabel(app.activeSprite, metadata.label)
    if srcCel == nil then return end
    local offset_x,offset_y = GetCelOffsetFromSrcCel(srcCel, dstCel)

    metadata.offset_x = offset_x
    metadata.offset_y = offset_y
    SetCelMetaData(dstCel, metadata)
end

function StoreOffsetFromSrcCels(layer, frameNumbers)
    for j,frameNumber in ipairs(frameNumbers) do
        local cel = layer:cel(frameNumber)
        if cel ~= nil then
            StoreOffsetFromSrcCel(cel)
        end
    end
end

-------------------------------------------------------------------------------
-- 暫定対処用（app.activeSprite.celsが取れない用）
-------------------------------------------------------------------------------
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

function CelsLoop(callback)
    local layers, frameNumbers = GetTargetLayerAndFrameNumbers()
    for i,layer in ipairs(layers) do
        for j,frameNumber in ipairs(frameNumbers) do
            local cel = layer:cel(frameNumber)
            if cel ~= nil then
                callback(cel, frameNumbers)
            end
        end
    end
end

function GetAllSrcCelLabels(sprite)
    local labels = {}
    for i,cel in ipairs(sprite.cels) do
        local metadata = GetCelMetaData(cel)
        if metadata ~= nil and metadata.mt == METADATA_TYPE.LINK_CEL and metadata.is_src then
            if not contains(labels, metadata.label) then
                labels[#labels+1] = metadata.label
            end
        end
    end
    return labels
end

function GetAllSrcCels(sprite)
    local cels = {}
    for i,cel in ipairs(sprite.cels) do
        local metadata = GetCelMetaData(cel)
        if metadata ~= nil and metadata.mt == METADATA_TYPE.LINK_CEL and metadata.is_src then
            cels[#cels+1] = cel
        end
    end
    return cels    
end

function GetAllDstCels(sprite)
    local cels = {}
    for i,cel in ipairs(sprite.cels) do
        local metadata = GetCelMetaData(cel)
        if metadata ~= nil and metadata.mt == METADATA_TYPE.LINK_CEL and not metadata.is_src then
            cels[#cels+1] = cel
        end
    end
    return cels    
end

function ResetCelsColor(sprite)
    local labels = GetAllSrcCelLabels(sprite)
    local labelColors = {}
    if #labels <= 360 then
        local step = math.floor(360/#labels)
        for i = 0, #labels-1 do
            local c = Color{ h=i*step, s=1.0, v=1.0 }
            labelColors[tostring(labels[i+1])] = c
        end
    else
        return
    end

    local dstCels = GetAllDstCels(sprite)
    for i, cel in ipairs(dstCels) do
        local metadata = GetCelMetaData(cel)
        local c = labelColors[tostring(metadata.label)]
        c.alpha = 80
        cel.color = c
    end
    local srcCels = GetAllSrcCels(sprite)
    for i, cel in ipairs(srcCels) do
        local metadata = GetCelMetaData(cel)
        local c = labelColors[tostring(metadata.label)]
        c.alpha = 150
        cel.color = c
    end
end
-------------------------------------------------------------------------------
--
-- メイン処理
--
-------------------------------------------------------------------------------
--- 結合を解除して、新しいDstCelを作成する
function CreateDstCelsAndUnlink()
    app.transaction(
        function()
            -- for i,cel in ipairs(app.range.cels) do
            --     SetDstCelAndUnLink(cel)
            -- end
            CelsLoop(SetDstCelAndUnLink)
        end
    )
    CacheReset()
    app.refresh()
end

--- 結合を解除せず、新しいDstCelを作成する
function CreateDstCels()
    app.transaction(
        function()
            -- for i,cel in ipairs(app.range.cels) do
            --     SetDstCelAndUnLink(cel)
            -- end
            CelsLoop(SetDstCel)
        end
    )
    CacheReset()
    app.refresh()
end
