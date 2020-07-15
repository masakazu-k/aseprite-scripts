
--- クリップボード
local ClipboradData = {
    layer_metadata = nil,
    cels = {}
}

--- クリップボードをリセットする
function ResetClipborad()
    ClipboradData = {
        layer_metadata = nil,
        cels = {}
    }
end

--- クリップボード用の情報を取得する
local function ExtractCelInfo(layer, frameNumber)
    local layer_metadata = GetLayerMetaData(layer)
    local cel = layer:cel(frameNumber)
    if cel == nil then
        return {
            layer_metadata = layer_metadata,
            cel_metadata = nil,
            layer = layer,
            frameNumber = frameNumber,
            cel = nil,
            linkedFrameNumbers = nil
        }
    end

    local cel_metadata = GetCelMetaData(cel)
    local linkedFrameNumbers = SearchLinkedCels(layer, frameNumber)
    return {
        layer_metadata = layer_metadata,
        cel_metadata = cel_metadata,
        layer = layer,
        frameNumber = frameNumber,
        cel = cel,
        linkedFrameNumbers = linkedFrameNumbers
    }
end

--- クリップボードにCel情報を追加する
function CopyFromRange(layer, frameNumbers)
    ResetClipborad()
    ClipboradData.layer_metadata = GetLayerMetaData(layer)
    for i, frameNumber in ipairs(frameNumbers) do
        ClipboradData.cels[#ClipboradData.cels+1] = ExtractCelInfo(layer, frameNumber)
    end
end

--- クリップボードからデータを貼り付ける
function PasteToRange(layer, frameNumbers)
    -- 未コピーの場合、処理終了
    if #ClipboradData.cels == 0 then return end

    -- コピー基点
    local dstBaseFrameNumber = frameNumbers[1]
    local srcBaseFrameNumber = ClipboradData.cels[1].frameNumber

    -- コピー先範囲を求める
    local dstFrameNumbers = {}
    for i,celdata in ipairs(ClipboradData.cels) do
        dstFrameNumbers[#dstFrameNumbers+1] = dstBaseFrameNumber + (celdata.frameNumber-srcBaseFrameNumber)
    end

    local layer_metadata = GetLayerMetaData(layer)
    if layer_metadata == nil then
        SetDstCelsAndUnLink(layer, dstFrameNumbers)
        for i,celdata in ipairs(ClipboradData.cels) do
            local cel = layer:cel(dstFrameNumbers[i])
            if cel ~= nil then
                local cel_metadata = GetCelMetaData(cel)
                if cel_metadata ~= nil then
                    cel_metadata.offset_x = celdata.cel_metadata.offset_x
                    cel_metadata.offset_y = celdata.cel_metadata.offset_y
                    SetCelMetaData(cel, cel_metadata)
                end
            end
            CopyFromSrcCels(layer, dstFrameNumbers)
        end
    elseif layer_metadata.mt == METADATA_TYPE.EXPORT_LAYER then
        for i,celdata in ipairs(ClipboradData.cels) do
            local cel = layer:cel(dstFrameNumbers[i])
            if cel ~= nil then
                local cel_metadata = GetCelMetaData(cel)
                if cel_metadata ~= nil then
                    cel_metadata.offset_x = celdata.cel_metadata.offset_x
                    cel_metadata.offset_y = celdata.cel_metadata.offset_y
                    SetCelMetaData(cel, cel_metadata)
                end
            end
            DoMergeCommand(layer, dstFrameNumbers)
        end
    elseif layer_metadata.mt == METADATA_TYPE.COMMAND
     or layer_metadata.mt == METADATA_TYPE.DEFAULT then
    end    
end