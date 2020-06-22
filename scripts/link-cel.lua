

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

--- 指定のセルをディストセルに設定してリンクを解除する
local function SetDstCelAndUnLink(cel)
    local metadata = GetCelMetaData(cel)
    if metadata == nil then
        -- デフォルト
        -- 一旦どこかにソースセルがいることを信じる仕様にする
        metadata = CreateLinkMetaData()
        metadata.is_src = true
        SetCelMetaData(cel, metadata)
    else
        if metadata.mt ~= METADATA_TYPE.LINK_CEL then
            return false
        end
    end
    --- 既存のセルを削除したら消える事があるのでバックアップ
    local image = Image(cel.image)
    local position = cel.position
    --- 新しいセルを作成しリンクを切る
    local dstCel = app.activeSprite:newCel(cel.layer, cel.frame.frameNumber)
    metadata.is_src = false
    dstCel.image = image
    dstCel.position = position
    SetCelMetaData(dstCel, metadata)
    return true
end

--- TODO aseprite標準のリンク情報を残して、そこだけ分離したい
local function SetDstCel(cel)
    local metadata = GetCelMetaData(cel)
    if metadata == nil then
        SetDstCelAndUnLink(cel)
    else
        if metadata.mt ~= METADATA_TYPE.LINK_CEL then
            return false
        end
    end
    metadata.is_src = false
    SetCelMetaData(cel, metadata)
end

--- ソースセルと原点を比較しオフセットを取得する
function GetCelOffsetFromSrcCel(srcCel, dstCel)
    return srcCel.position.x - dstCel.position.x, srcCel.position.y - dstCel.position.y
end

local function CopyFromSrcCel(dstCel)
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
            CopyFromSrcCel(cel)
        end
    end
end

local function StoreOffsetFromSrcCel(dstCel)
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
                callback(cel)
            end
        end
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

function ChangeSourceCel()
    app.transaction(
        function()
            -- for i,cel in ipairs(app.range.cels) do
            --     SetOffsetFromSrcCel(cel)
            -- end
            -- CelsLoop(SetOffsetFromSrcCel)
        end
    )
    CacheReset()
    app.refresh()
end
