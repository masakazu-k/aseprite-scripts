local function add_layer(layer, layers)
    if layer.isGroup then
        for i,l in ipairs(layer.layers) do
            add_layer(l, layers)
        end
    end
    layers[#layers+1] = layer
end

local frameNumbers = {}
local layers = {}

local function align_center(base_cel, cel)
    if cel == nil then
        return
    end
    local base_center = Point{
        x = base_cel.position.x + base_cel.bounds.width/2,
        y = base_cel.position.y + base_cel.bounds.height/2
    }
    local next_pos = Point{
        x = base_center.x - cel.bounds.width/2,
        y = base_center.y - cel.bounds.height/2
    }
    cel.position = next_pos
end

local oldActiveFrame = app.activeFrame
local oldActiveLayer = app.activeLayer
for i,f in ipairs(app.range.frames) do
    frameNumbers[#frameNumbers+1] = f.frameNumber
end
for i,l in ipairs(app.range.layers) do
    add_layer(l, layers)
end
for i,l in ipairs(layers) do
    local isFirst = true
    local base_cel = nil
    for i,frameNumber in ipairs(frameNumbers) do
        if not isFirst then
            app.transaction(
                function()
                    align_center(base_cel, l:cel(frameNumber))
            end)
        else
            base_cel = l:cel(frameNumber)
            if base_cel ~= nil then
                isFirst = false
            end
        end
    end
end
app.activeFrame = oldActiveFrame
app.activeLayer = oldActiveLayer
app.refresh()