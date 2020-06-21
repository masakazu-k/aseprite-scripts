

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
    --- 新しいセルを作成しリンクを切る
    local dstCel = app.activeSprite:newCel(cel.layer, cel.frame.frameNumber)
    metadata.is_src = false
    CopyImageFromCel(cel, dstCel, metadata)
    SetCelMetaData(dstCel, metadata)
    return true
end


--- TODO 検索結果キャッシュ（セルは数が多いので検索結果をキャッシュする）
local _search_cache = {}
local function CacheReset()
    _search_cache = {}
end

--- labelで指定したソースセルを取得する
local function is_target_src_cel(cel, label)
    local metadata = GetCelMetaData(cel)
    if metadata == nil or metadata.mt ~= METADATA_TYPE.LINK_CEL then
        return false
    end
    if not metadata.is_src then
        return false
    end
    --- TODO キャッシュする
    _search_cache[metadata.label] = cel
    return metadata.label == label
end

local function SearchSrcCelByLabel(label)
    if _search_cache[label] ~= nil then
        return _search_cache[label]
    end

    for i, cel in ipairs(app.activeSprite.cels) do
        if is_target_src_cel(cel, label) then
            return cel
        end
    end
    return nil   
end

--- ソースセルと原点を比較しオフセットを取得する
function GetCelOffsetFromSrcCel(srcCel, dstCel)
    return srcCel.position.x - dstCel.position.x, srcCel.position.y - dstCel.position.y
end

local function CopyFromSrcCel(dstCel)
    local metadata = GetCelMetaData(dstCel)
    if metadata == nil or metadata.mt ~= METADATA_TYPE.LINK_CEL then return end
    if metadata.is_src then return end

    local srcCel = SearchSrcCelByLabel(metadata.label)
    if srcCel == nil then return end

    CopyImageFromCel(srcCel, dstCel, metadata)
end


local function SetOffsetFromSrcCel(dstCel)
    local metadata = GetCelMetaData(dstCel)
    if metadata == nil or metadata.mt ~= METADATA_TYPE.LINK_CEL then return end
    if metadata.is_src then return end

    local srcCel = SearchSrcCelByLabel(metadata.label)
    if srcCel == nil then return end
    local offset_x,offset_y = GetCelOffsetFromSrcCel(srcCel, dstCel)

    metadata.offset_x = offset_x
    metadata.offset_y = offset_y
    SetCelMetaData(dstCel, metadata)
end

function UnLinkCels()
    app.transaction(
        function()
            for i,cel in ipairs(app.range.cels) do
                SetDstCelAndUnLink(cel)
            end
        end
    )
    CacheReset()
    app.refresh()
end

function CopyFromSrcCels()
    app.transaction(
        function()
            for i,cel in ipairs(app.range.cels) do
                CopyFromSrcCel(cel)
            end
        end
    )
    CacheReset()
    app.refresh()
end

function SetOffsetFromSrcCels()
    app.transaction(
        function()
            for i,cel in ipairs(app.range.cels) do
                SetOffsetFromSrcCel(cel)
            end
        end
    )
    CacheReset()
    app.refresh()
end