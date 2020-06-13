-- 文字列分割
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

function contains(arry, item)
    for i in pairs(arry) do
        if item == i then
            return true
        end
    end
    return false
end