
-------------------------------------------
--
-- constants
--
-------------------------------------------
local MASKED_IMG_GROUP_NAME = "masked_img"
local MASKED_IMG_LAYER_NAME = "msked_"
local MASK_LAYER_NAME = "msk_"

-------------------------------------------
-- utils
-------------------------------------------
local function starts_with(str, start)
    if str == nil or #str < #start then
      return false
    else
      return str == start or str:sub(1, #start) == start
    end
end

-- 指定されたレイヤーを探す
local function search_masked_layer(sprite, layer_name)
  for i = #sprite.layers, 1, -1 do
    if sprite.layers[i].isImage and sprite.layers[i].name == layer_name then
      return sprite.layers[i]
    end
  end
  return nil
end

-------------------------------------------
-- visible utils
-------------------------------------------
-- 現在の表示状態を取得する
function visible_list(sprite)
  local visbles = {}
  for i = 1,#sprite.layers do
    visbles[i] = sprite.layers[i].isVisible
  end
  return visbles
end

-- 全イメージレイヤーを不可視状態にする
function unvisible_all_layer(sprite)
  for i = 1,#sprite.layers do
    if sprite.layers[i].isImage then
      sprite.layers[i].isVisible = false
    end
  end
end

-- 全レイヤーの可視状態を復元する
function restore_all_layer(sprite, visibles)
  for i = 1,#sprite.layers do
    sprite.layers[i].isVisible = visibles[i]
  end
end

-- レイヤーの可視状態を復元する
function restore_layer(layer, visibles, index)
  layer.isVisible = visibles[index]
end

-- 指定されたレイヤーがマスクであるかチェックする
local function is_mask_layer(layer)
  return layer.isImage and starts_with(layer.name, MASK_LAYER_NAME)
end

-- 指定されたレイヤーがセルフマスクであるかチェックする
local function is_self_mask_layer(layer)
  return layer.isImage and starts_with(layer.data, MASKED_IMG_LAYER_NAME)
end

-- 指定されたレイヤーがセルフマスクであるかチェックする
local function is_self_mask_cel(layer, frameNumber)
  local c = layer:cel(frameNumber)
  return c ~= nil and starts_with(c.data, MASKED_IMG_LAYER_NAME)
end

-- bug対策：レイヤーからセルを取得できないため、スプライトのセル一覧から取得する
local function search_target_cel(sprite, msk_layer, frameNumber)
  for i = 1,#sprite.cels do
    local c = sprite.cels[i]
    if c.layer == msk_layer and c.frameNumber == frameNumber then
      return c
    end
  end
  return nil
end

-- 指定されたマスクレイヤーのマスク対象エリアをPointで取得する
local function get_mask_points(sprite, msk_layer, frameNumber)
  local points = {}
  local c = msk_layer:cel(frameNumber)
  local area = nil
  if c == nil then
    c = search_target_cel(sprite, msk_layer, frameNumber)
  end
  if c ~= nil then
    for it in c.image:pixels() do
      local pixelValue = it() -- get pixel
      if app.pixelColor.rgbaA(pixelValue) > 0 then
        points[#points + 1] = Point(it.x + c.position.x, it.y + c.position.y)
      end
    end
  end
  return points
end

-------------------------------------------
-- masked layer  util
-------------------------------------------
-- 指定されたレイヤーがマスクであるかチェックする
local function is_masked_layer(layer)
  return layer.isImage and starts_with(layer.name, MASKED_IMG_LAYER_NAME)
end

-- 
local function get_masked_(name)
  if #MASKED_IMG_LAYER_NAME >= #name then
    return MASKED_IMG_LAYER_NAME
  end
  return MASKED_IMG_LAYER_NAME .. name:sub(#MASK_LAYER_NAME + 1, #name)
end

-- 指定されたマスクレイヤーに対応する、マスク済みレイヤー名を取得する
local function get_masked_layer_name(msk_layer)
  return get_masked_(msk_layer.name)
end

-- 指定されたマスクレイヤーに対応する、マスク済みレイヤー名を取得する
local function get_self_masked_layer_name(msk_layer)
  return msk_layer.data
end

-- 指定されたマスクレイヤーに対応する、マスク済みレイヤー名を取得する
local function get_cel_masked_layer_name(msk_layer, frameNumber)
  return msk_layer:cel(frameNumber).data
end

-- 全マスクレイヤーを取得する
local function get_all_mask_layer(sprite)
  local mask_layer = {}
  for i = 1,#sprite.layers do
    local layer = sprite.layers[i]
    if is_mask_layer(layer) then
      mask_layer[#mask_layer + 1] = layer
    end
  end
  return mask_layer
end

-- 指定された色のマスク済みレイヤーを取得する
function get_masked_layer_by_color(msked_layers, color)
  for key, layer in pairs(msked_layers) do
    if layer.color == color then
      return layer
    end
  end
  return nil
end

-- 指定された名前のマスク済みレイヤーを取得する
function get_masked_layer_by_name(msked_layers, name)
  return msked_layers[get_masked_layer_name(layer)]
end

-- 指定されたレイヤーとマスク済みレイヤーを紐づける（同じ色を設定する/dataに名前を付ける）
function set_masked_layer_to_layer(msked_layers, layer)
  layer.color = msked_layers.color
  layer.data = msked_layers.name
end

-- 指定されたレイヤーのマスク済みレイヤーを解除する
function unset_masked_layer_to_layer(layer)
  layer.color = Color()
  layer.data = ""
end

-- 指定されたセルとマスク済みレイヤーを紐づける（同じ色を設定する/dataに名前を付ける）
function set_masked_layer_to_cel(msked_layers, cel)
  cel.color = msked_layers.color
  cel.data = msked_layers.name
end

-- 指定されたセルとマスク済みレイヤーを紐づける（同じ色を設定する/dataに名前を付ける）
function unset_masked_layer_to_cel(cel)
  cel.color = Color()
  cel.data = ""
end

-- マスク済みレイヤーリストを取得する
local function get_masked_layers(sprite)
  local masked_layers = {}
  for i = #sprite.layers, 1, -1 do
    local layer = sprite.layers[i]
    if is_masked_layer(layer) then
      masked_layers[layer.name] = layer
    end
  end
  return masked_layers
end

-- デフォルトのマスク済みレイヤーを取得する
local function get_default_masked_layer(sprite)
  if sprite.layers[#sprite.layers].name == MASKED_IMG_LAYER_NAME then
    return sprite.layers[#sprite.layers]
  end
  local deflayer = search_masked_layer(sprite, MASKED_IMG_LAYER_NAME)
  if deflayer ~= nil then
    return deflayer
  else
    sprite:newLayer()
    local firstLayer = sprite.layers[#sprite.layers]
    firstLayer.name = MASKED_IMG_LAYER_NAME
    return firstLayer
  end
end

-- 指定されたマスクレイヤーのマスク対象エリアを取得する
local function get_mask_area(sprite, msk_layer, frameNumber)
  local points = {}
  local c = msk_layer:cel(frameNumber)
  local area = nil
  if c == nil then
    c = search_target_cel(sprite, msk_layer, frameNumber)
  end
  if c ~= nil then
    for it in c.image:pixels() do
      local pixelValue = it() -- get pixel
      --app.alert("("..tostring(it.x)..","..tostring(it.y)..")A:"..tostring(app.pixelColor.rgbaA(it())))
      if app.pixelColor.rgbaA(pixelValue) > 0 then
        if area == nil then
          area = Rectangle(it.x+c.position.x, it.y+c.position.y, 1, 1)
        else
          area = area:union(Rectangle(it.x+c.position.x, it.y+c.position.y, 1, 1))
        end
      end
    end
  end
  return area
end

-------------------------------------------
-- mask process utils
-------------------------------------------
local function copy_area(sprite, msked_layer, frameNumber)
  -- コピー操作をするフレームを選択
  app.activeFrame = sprite.frames[frameNumber]

  local msked_layer_visible = msked_layer.isVisible

  -- マスク対象エリアをコピー（マージ済み）
  app.command.CopyMerged()

  -- ペースト先を選択
  app.activeLayer = msked_layer

  -- ペーストのために表示
  msked_layer.isVisible = true

  -- マスク対象エリアをペースト
  app.command.Paste()

  msked_layer.isVisible = msked_layer_visible
end

local function copy_dep_marged_image(sprite, msk_layer, msked_layer, frameNumber)
  local msked_layer_visible = msked_layer.isVisible
  -- マスク対象エリアを取得
  local mask_area = get_mask_points(sprite, msk_layer, frameNumber)
  if mask_area == nil then
    return
  end

  sprite.selection:deselect()
  for i = 1,#mask_area do
    local p = mask_area[i]
    local r = Rectangle(p.x, p.y, 1 ,1)
    -- マスク対象エリアを選択
    sprite.selection:add(Selection(r))
    -- sprite.selection:select(r)
  end
  if sprite.selection.isEmpty == false then
    copy_area(sprite, msked_layer, frameNumber)
  end
  sprite.selection:deselect()
end

local function copy_marged_image(sprite, msk_layer, msked_layer, frameNumber)
  sprite.selection:deselect()

  local msked_layer_visible = msked_layer.isVisible
  -- マスク対象エリアを取得
  local mask_area = get_mask_area(sprite, msk_layer, frameNumber)
  if mask_area == nil then
    do return end
  end
  -- マスク対象エリアを選択
  sprite.selection:select(mask_area)
  
  app.activeLayer = msk_layer
  app.activeFrame = sprite.frames[frameNumber]

  -- マスク対象エリアをコピー（マージ済み）
  app.command.CopyMerged()

  -- ペースト先を選択
  app.activeLayer = msked_layer
  app.activeFrame = sprite.frames[frameNumber]

  -- ペーストのために表示
  msked_layer.isVisible = true

  -- マスク対象エリアをペースト
  app.command.Paste()

  msked_layer.isVisible = msked_layer_visible
  
  sprite.selection:deselect()
end

-- すべてのフレームをコピーする
function copy_dep_marged_image_all(sprite, msk_layer, msked_layer)
  for j = 1,#sprite.frames do
    copy_dep_marged_image(sprite, msk_layer, msked_layer, j)
  end
end
-------------------------------------------
-- main function
-------------------------------------------
function update_masked_image()
  local sprite = app.activeSprite
  local masked_layers = get_masked_layers(sprite)
  local masked_layer = get_default_masked_layer(sprite)
  local visbles = visible_list(sprite)

  unvisible_all_layer(sprite)
  
  -- マスク結果をクリア
  for key, layer in pairs(masked_layers) do
    for j = 1,#sprite.frames do
      local c = layer:cel(j)
      if c == nil then
        c = search_target_cel(sprite, layer, j)
      end
      if c ~= nil then
        c.image:clear()
      end
    end
  end

  -- マスク対象エリアをマスク
  for i = 1,#sprite.layers do
    local layer = sprite.layers[i]
    if is_mask_layer(layer) then
      local each_mask_layer = masked_layers[get_masked_layer_name(layer)]
      if each_mask_layer ~= nil then
        copy_dep_marged_image_all(sprite, layer, each_mask_layer)
      else
        copy_dep_marged_image_all(sprite, layer, masked_layer)
      end
    end
    restore_layer(layer, visbles, i)
    if is_self_mask_layer(layer) then
      local each_mask_layer = masked_layers[get_self_masked_layer_name(layer)]
      if each_mask_layer ~= nil then
        copy_dep_marged_image_all(sprite, layer, each_mask_layer)
      else
        copy_dep_marged_image_all(sprite, layer, masked_layer)
      end
    end
    for j = 1,#sprite.frames do
      if is_self_mask_cel(layer, j) then
        local each_mask_layer = masked_layers[get_cel_masked_layer_name(layer, j)]
        if each_mask_layer ~ nil then
          copy_dep_marged_image(sprite, layer, each_mask_layer, j)
        else
          copy_dep_marged_image(sprite, layer, masked_layer, j)
        end
      end
    end
  end
  restore_all_layer(sprite, visbles)

  app.refresh()
end

function auto_update_masked_layers()
  local sprite = app.activeSprite
  local default_masked_layer = get_default_masked_layer(sprite)
  local masked_layers = get_masked_layers(sprite)

  for i = 1,#sprite.layers do
    local layer = sprite.layers[i]
    app.alert(" "..layer.name)
    if is_mask_layer(layer) then
      local each_mask_layer = masked_layers[get_masked_layer_name(layer)]
      if each_mask_layer ~= nil then
        set_masked_layer_to_layer(each_mask_layer, layer)
      else
        set_masked_layer_to_layer(default_masked_layer, layer)
      end
    end
    if is_self_mask_layer(layer) then
      local each_mask_layer = masked_layers[get_self_masked_layer_name(layer)]
      if each_mask_layer ~= nil then
        set_masked_layer_to_layer(each_mask_layer, layer)
      else
        set_masked_layer_to_layer(default_masked_layer, layer)
      end
    end
    for j = 1,#sprite.frames do
      if is_self_mask_cel(layer, j) then
        local each_mask_layer = masked_layers[get_cel_masked_layer_name(layer, j)]
        if each_mask_layer ~ nil then
          set_masked_layer_to_cel(msked_layer, cel)
        else
          set_masked_layer_to_cel(default_masked_layer, layer)
        end
      end
    end
  end

  app.refresh()
end

function set_masked_layer()
  local sprite = app.activeSprite
  if app.range.type == RangeType.EMPTY then
    app.alert("NOT SELECTED LAYER OR CEL")
    return
  elseif app.range.type == RangeType.FRAMES then
    app.alert("NOT SELECTED LAYER OR CEL")
    return
  end

  local default_masked_layer = get_default_masked_layer(sprite)
  local masked_layers = get_masked_layers(sprite)

  local options = {}

  for key, value in pairs(masked_layers) do 
    options[#options + 1] = key
  end

  local dlg = Dialog("Select Masked Layer")
  local data = dlg
    :combobox{ id="selected_masked_layer", label="Masked Layer", option=options[1], options=options }
    :newrow()
    :button{ id="ok", text="OK" }
    :button{ id="cancel", text="Cancel" }
    :show().data
  if data.cancel then
    return
  end

  local msked_layer = masked_layers[data.selected_masked_layer]

  if msked_layer == nil then
    return
  end

  if app.range.type == RangeType.LAYERS then
    for i = 1,#app.range.layers do
      local layer = app.range.layers[i]
      if is_masked_layer(layer) ~= true then
        set_masked_layer_to_layer(msked_layer, layer)
      end
    end
  elseif app.range.type == RangeType.CELS then
    for i = 1,#app.range.cels do
      local cel = app.range.cels[i]
      set_masked_layer_to_cel(msked_layer, cel)
    end
  end
  app.refresh()
end

function unset_masked_layer()
  local sprite = app.activeSprite
  if app.range.type == RangeType.EMPTY then
    app.alert("NOT SELECTED LAYER OR CEL")
    return
  end

  if app.range.type == RangeType.LAYERS then
    for i = 1,#app.range.layers do
      local layer = app.range.layers[i]
      if is_masked_layer(layer) ~= true then
        unset_masked_layer_to_layer(layer)
      end
    end
  elseif app.range.type == RangeType.CELS then
    for i = 1,#app.range.cels do
      local cel = app.range.cels[i]
      unset_masked_layer_to_cel(cel)
    end
  elseif app.range.type == RangeType.FRAMES then
    for i = 1,#app.range.frames do
      local frame = app.range.frames[i]
      for j = 1,#sprite.layers do
        local cel = sprite.layers[j]:cel(frame.frameNumber)
        if cel ~= nil then
          unset_masked_layer_to_cel(cel)
        end
      end
    end
  end
  app.refresh()
end




-------------------------------------------
--
-- create masked image data
--
-------------------------------------------

function update()
  app.transaction(
    function()
      local l = app.activeLayer
      local f = app.activeFrame 
      update_masked_image()
      app.activeLayer = l
      app.activeFrame = f
    end
  )
end

function refresh()
  app.transaction(
    function()
      auto_update_masked_layers()
    end
  )
end

function setmask()
  app.transaction(
    function()
      set_masked_layer()
    end
  )
end

function unsetmask()
  app.transaction(
    function()
      unset_masked_layer()
    end
  )
end

local dlg = Dialog("dMask Toolbar")
dlg
  :button{text="Update Masked Layer", onclick=update}
  :newrow()
  :button{text="Refresh Group Color", onclick=refresh}
  :newrow()
  :separator()
  :button{text="Set Mask", onclick=setmask}
  :button{text="Unset Mask", onclick=unsetmask}
  -- :combobox{ id="mode", label="Mask Mode", option="Multiple", options={ "Single", "Multiple" } }
  :show{wait=false}
