


local function extract_tag_info(tag, tags)
    local tag_name = tag.name
    local info = split(tag_name,"=")
    local tag_cnt = -1

    if #info == 2 then
        tag_cnt = tonumber(info[2])
    end

    local tag_info = {tag=tag, base_name=info[1], cnt=tag_cnt}
    return tag_info
end

local function copy_deep_cels(layer, from, to, count, tidx)
    if layer.isImage then
        for fi=from, to do
            local target = fi + count*(tidx-1)
            LinkCels(layer, {fi, target})
            -- local src = layer:cel(fi)
            -- if src ~= nil then
            --     sprite:newCel(layer, target, src.image, src.position)
            -- end
        end
    else
        -- グループ配下の全レイヤーを処理
        for i,l in ipairs(layer.layers) do
            copy_deep_cels(l, from, to, count, tidx)
        end
    end
end

local function copy_cels(sprite, from, to, count, tidx)
    for i,l in ipairs(sprite.layers) do
        copy_deep_cels(l, from, to, count, tidx)
    end
end

local function amplification_by_count(tag_info, sprite)
    local from = tag_info.tag.fromFrame.frameNumber
    local to = tag_info.tag.toFrame.frameNumber
    local count = to - from + 1

    app.activeFrame = to
    for tidx=1, tag_info.cnt-1 do
        for fidx=1, count do
            app.command.NewFrame{content="empty"}
        end
    end

    --app.command.NewFrame{content="celcopies"}
    --app.command.NewFrame{content="cellinked"}
    for tidx=1, tag_info.cnt do
        local tag = sprite:newTag(from + count*(tidx-1),from + count*(tidx)-1)
        tag.name = tag_info.base_name.."@"..tostring(tidx)
        if tidx > 1 then
            copy_cels(sprite,from,to, count, tidx)
        end
    end

    sprite:deleteTag(tag_info.tag)
    local next_start = to + 1
end

function LoopExtending()
    local sprite = app.activeSprite

    if sprite == nil then 
        app.alert("スプライトを開いて")
        return
    end
    
    app.transaction(
    function()

        sprite = Sprite(sprite)
        app.activeSprite = sprite
        app.refresh()
        
        for i,tag in ipairs(sprite.tags) do
            local tag_info = extract_tag_info(tag, sprite.tags)
            if tag_info.cnt >= 0 then
                amplification_by_count(tag_info, sprite)
                -- app.alert("count"..tag_info.cnt)
            end
        end
    end)
end