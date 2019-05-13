-------------------------------------------
-- Base Utils
-------------------------------------------
local function starts_with(str, start)
  if str == nil or #str < #start then
    return false
  else
    return str == start or str:sub(1, #start) == start
  end
end

-- 指定されたレイヤーを探す
local function search_export_layer(sprite, layer_name)
  for i = #sprite.layers, 1, -1 do
    if sprite.layers[i].isImage and sprite.layers[i].name == layer_name then
      return sprite.layers[i]
    end
  end
  return nil
end

-------------------------------------------
-- Export Layer
-------------------------------------------
local EXPORT_LAYER_NAME_PREFIX = "export_"
local ExportLayer = {}

-- Export Layer Type
ExportLayer.Type = {}
ExportLayer.Type.Marged = "Marged"
ExportLayer.Type.Self = "Self"
ExportLayer.Type.Inverse = "Inverse"

-- Export Layer Class
ExportLayer.Class = function(layer)
  local self = {}

  if (layer.data == ExportLayer.Type.Marged or
  layer.data == ExportLayer.Type.Self or
  layer.data == ExportLayer.Type.Inverse) ~= true then
    layer.data =ExportLayer.Type.Marged
  end

  self.layer = layer
  self.type = layer.data
  
  -- 編集ダイアログを表示する
  self.EditorShow = function(self)
    local dlg = Dialog("Export Layer")
    local options = {
      ExportLayer.Type.Marged,
      ExportLayer.Type.Self,
      ExportLayer.Type.Inverse}
    local data = dlg
      :combobox{ id="type", label="Mask Type", option=self.layer.data, options=options }
      :newrow()
      :button{ id="ok", text="OK" }
      :button{ id="cancel", text="Cancel" }
      :show().data
    if data.ok then
      self.layer.data = data.type
      self.type = data.type
    end
  end

  -- クリア
  self.Clear = function(self, frameNumber)
    local c = self.layer:cel(frameNumber)
    if c ~= nil then
      c.image:clear()
    end
  end

  return self
end

-- Export Layerを作成する
ExportLayer.New = function(sprite, name)
  local new_layer = sprite:newLayer()
  new_layer.name = EXPORT_LAYER_NAME_PREFIX..name
  new_layer.data = ExportLayer.Type.Marged
  return ExportLayer.Class(new_layer)
end

-- Export Layerか確認する
ExportLayer.Is = function(layer)
  return layer.isImage and starts_with(layer.name, EXPORT_LAYER_NAME_PREFIX)
end

-- 指定された名前のExport Layerを検索する
ExportLayer.Search = function(sprite, name)
  for i = #sprite.layers, 1, -1 do
    local layer = sprite.layers[i]
    if ExportLayer.Is(layer) and layer.name == name then
      return layer
    end
  end
  return nil
end

-- デフォルトExport Layerを取得する、なければ作る
ExportLayer.Default = function(sprite)
  local deflayer = ExportLayer.Search(sprite, EXPORT_LAYER_NAME_PREFIX)
  if deflayer ~= nil then
    return ExportLayer.Class(deflayer)
  else
    return ExportLayer.New(sprite, "")
  end
end

-- すべてのExport Layerを取得する（連想配列）
ExportLayer.All = function(sprite)
  local export_layers = {}
  for i = #sprite.layers, 1, -1 do
    local layer = sprite.layers[i]
    if ExportLayer.Is(layer) then
      export_layers[layer.name] = ExportLayer.Class(layer)
    end
  end
  return export_layers
end

-------------------------------------------
-- Mask Cel
-------------------------------------------
local MaskCel = {}

-- 指定されたマスクレイヤーのマスク対象エリアをPointで取得する
local function get_mask_points(cel)
  local points = {}
  if cel ~= nil then
    for it in cel.image:pixels() do
      local pixelValue = it() -- get pixel
      if app.pixelColor.rgbaA(pixelValue) > 0 then
        points[#points + 1] = Point(it.x + cel.position.x, it.y + cel.position.y)
      end
    end
  end
  return points
end

-- Mask Cel クラス
MaskCel.Class = function(cel)
  local self = {}
  self.cel = cel

  -- マスク範囲を選択する
  self.Select = function(self)
    local points = get_mask_points(self.cel)
    for i = 1, #points do
      local p = points[i]
      local r = Rectangle(p.x, p.y, 1 ,1)
      -- マスク対象エリアを選択
      self.cel.sprite.selection:add(Selection(r))
      app.refresh()
    end
  end
  return self
end

-- Mask Celを作成する
MaskCel.New = function(cel, export_layer)
  cel.data = export_layer.layer.name
  cel.color = export_layer.layer.color
  return MaskCel.Class(cel)
end

-- Mask Layerを解除する
MaskCel.UnSetCel = function(cel)
  cel.data = ""
  cel.color = Color()
  return nil
end

-- Mask Layerを作成する
MaskCel.SetLayer = function(layer, export_layer)
  layer.data = export_layer.layer.name
  layer.color = export_layer.layer.color
  return nil
end

-- Mask Layerを解除する
MaskCel.UnSetLayer = function(layer)
  layer.data = ""
  layer.color = Color()
  return nil
end

-- 指定されたレイヤーが指定されたフレームでマスクであるかチェックする
MaskCel.Is = function(layer, frameNumber)
  return MaskCel.IsLayer(layer) or MaskCel.IsCel(layer, frameNumber)
end

-- 指定されたレイヤーが指定されたフレームでマスクであるかチェックする
MaskCel.IsLayer = function(layer)
  if layer.isImage then
    if starts_with(layer.data, EXPORT_LAYER_NAME_PREFIX) then
      return true
    end
  end
  return false
end

-- 指定されたレイヤーが指定されたフレームでマスクであるかチェックする
MaskCel.IsCel = function(layer, frameNumber)
  if layer.isImage then
    local c = layer:cel(frameNumber)
    if c ~= nil and starts_with(c.data, EXPORT_LAYER_NAME_PREFIX) then
      return true
    end
  end
  return false
end
-- bug対策：レイヤーからセルを取得できないため、スプライトのセル一覧から取得する
local function search_target_cel(sprite, layer, frameNumber)
  for i = 1,#sprite.cels do
    local c = sprite.cels[i]
    if c.layer == layer and c.frameNumber == frameNumber then
      return c
    end
  end
  return nil
end

-- 指定されたフレームで有効なCelをすべて取得する（連想配列）
MaskCel.All = function(sprite, frameNumber)
  local mask_cels = {}
  for i = 1, #sprite.layers do
    local layer = sprite.layers[i]
    local name = nil
    local c = layer:cel(frameNumber)
    if MaskCel.IsCel(layer, frameNumber) then
      name = c.data
    elseif MaskCel.IsLayer(layer) then
      name = layer.data
    end
    if name ~= nil and c ~= nil then
      if mask_cels[name] == nil then
        mask_cels[name] = {}
      end
      mask_cels[name][#mask_cels[name] + 1] = MaskCel.Class(c)
    end
  end
  return mask_cels
end

-------------------------------------------
-- visible utils
-------------------------------------------
-- 現在の表示状態を取得する
function visible_list(sprite)
  local visibles = {}
  for i = 1,#sprite.layers do
    visibles[i] = sprite.layers[i].isVisible
  end
  return visibles
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

-------------------------------------------
-- Mask Manager
-------------------------------------------
local MaskManager = {}
MaskManager.Class = function(sprite)
  local self = {}
  self.sprite = sprite
  self.default_export_layer = ExportLayer.Default(sprite)
  self.export_layers = ExportLayer.All(sprite)
  self.visibles = visible_list(sprite)

  -- 指定されたフレームについてExport Layerを更新
  self.UpdateAll = function(self)
    self.sprite.selection:deselect()
    self.sprite.selection.origin.x = 0
    self.sprite.selection.origin.y = 0
    for i = 1,#self.sprite.frames do
      self:Update(i)
    end
    self.sprite.selection:deselect()
  end

  -- 指定されたフレームについてExport Layerを更新
  self.Update = function(self, frameNumber)
    local mask_cels = MaskCel.All(self.sprite, frameNumber)
    for key, export_layer in pairs(self.export_layers) do
      -- 不可視状態にする
      unvisible_all_layer(self.sprite)
      self.sprite.selection:deselect()
      export_layer:Clear(frameNumber)
      self:Select(mask_cels, export_layer)
      self:Copy(frameNumber)
      self:Paste(export_layer, frameNumber)
      self.sprite.selection:deselect()
    end
    restore_all_layer(self.sprite, self.visibles)
  end

  self.Select = function(self, mask_cels, export_layer)
    local cels = mask_cels[export_layer.layer.name]
    if cels == nil then 
      return
    end

    if export_layer.type == ExportLayer.Type.Marged or 
    export_layer.type == ExportLayer.Type.Inverse then
      -- マスクより下のレイヤを表示
      local lastLayer = cels[#cels].cel.layer
      for i = 1,#self.sprite.layers do
        restore_layer(self.sprite.layers[i], self.visibles, i)
        if self.sprite.layers[i] == lastLayer then
          break
        end
      end
    elseif export_layer.type == ExportLayer.Type.Self then
      -- マスクのみ表示
      for i = 1,#cels do
        local lastInbdex = 1
        for j = lastInbdex,#self.sprite.layers do
          if self.sprite.layers[j] == cels[i].cel.layer then
            restore_layer(self.sprite.layers[j], self.visibles, j)
            lastInbdex = j
            break
          end
        end
      end
    end

    -- マスク範囲を選択する
    for i = 1, #cels do
      cels[i]:Select()
    end
    

    -- 選択範囲を反転させる
    if export_layer.type == ExportLayer.Type.Inverse then
      app.command.InvertMask()
    end
  end

  -- コピー
  self.Copy = function(self, frameNumber)
    -- コピー操作をするフレームを選択
    app.activeFrame = self.sprite.frames[frameNumber]
    -- マスク対象エリアをコピー（マージ済み）
    if self.sprite.selection.isEmpty == false then
      app.command.CopyMerged()
    end
  end

  -- 貼り付け
  self.Paste = function(self, layer, frameNumber)
    -- ペースト操作をするフレームを選択
    app.activeFrame = self.sprite.frames[frameNumber]
    -- ペースト先を選択
    app.activeLayer = layer.layer

    local export_layer_visible = layer.layer.isVisible  
    -- ペーストのために表示
    layer.layer.isVisible = true
  
    if self.sprite.selection.isEmpty == false then
      -- マスク対象エリアをペースト
      app.command.Paste()
      app.refresh()
    end
  
    layer.layer.isVisible = export_layer_visible
  end

  self.EditorShow = function(self)
    if app.range.type == RangeType.EMPTY then
      app.alert("NOT SELECTED LAYER OR CEL")
      return
    elseif app.range.type == RangeType.FRAMES then
      app.alert("NOT SELECTED LAYER OR CEL")
      return
    end
  
    local options = {}
  
    for key, value in pairs(self.export_layers) do
      options[#options + 1] = key
    end
  
    local dlg = Dialog("Select Masked Layer")
    local data = dlg
      :combobox{ id="selected_export_layer", label="Masked Layer", option=options[1], options=options }
      :newrow()
      :button{ id="ok", text="OK" }
      :button{ id="cancel", text="Cancel" }
      :show().data
    if data.cancel then
      return
    end
  
    local export_layer = self.export_layers[data.selected_export_layer]
  
    if export_layer == nil then
      return
    end
  
    if app.range.type == RangeType.LAYERS then
      for i = 1,#app.range.layers do
        local layer = app.range.layers[i]
        if ExportLayer.Is(layer) ~= true then
          MaskCel.SetLayer(layer, export_layer)
        end
      end
    elseif app.range.type == RangeType.CELS then
      for i = 1,#app.range.cels do
        local cel = app.range.cels[i]
        if ExportLayer.Is(cel.layer) ~= true then
          MaskCel.New(cel, export_layer)
        end
      end
    end
  end

  self.Unset = function(self)
    if app.range.type == RangeType.EMPTY then
      app.alert("NOT SELECTED LAYER OR CEL")
      return
    end
  
    if app.range.type == RangeType.LAYERS then
      for i = 1,#app.range.layers do
        local layer = app.range.layers[i]
        if MaskCel.IsLayer(layer) then
          MaskCel.UnSetLayer(layer)
        end
      end
    elseif app.range.type == RangeType.CELS then
      for i = 1,#app.range.cels do
        local cel = app.range.cels[i]
        if MaskCel.IsCel(cel.layer, cel.frameNumber) then
          MaskCel.UnSetLayer(cel)
        end
      end
    end
  end

  self.UpdateColor = function(self)
    for i = 1,#self.sprite.layers do
      local layer = self.sprite.layers[i]
      if MaskCel.IsLayer(layer) then
        if self.export_layers[layer.data] ~= nil then
          layer.color = self.export_layers[layer.data].layer.color
        end
      end
      for j = 1,#self.sprite.frames do
        local cel = layer:cel(j)
        if cel ~= nil and MaskCel.IsCel(cel.layer, cel.frameNumber) then
          if self.export_layers[cel.data] ~= nil then
            cel.color = self.export_layers[cel.data].layer.color
          end
        end
      end
    end
  end
  return self
end

-- 指定されたセルとマスク済みレイヤーを紐づける（同じ色を設定する/dataに名前を付ける）
function set_export_layer_to_cel(export_layers, cel)
  cel.color = export_layers.color
  cel.data = export_layers.name
end

-- 指定されたセルとマスク済みレイヤーを紐づける（同じ色を設定する/dataに名前を付ける）
function unset_export_layer_to_cel(cel)
  cel.color = Color()
  cel.data = ""
end

-- マスク済みレイヤーリストを取得する
local function get_export_layers(sprite)
  local export_layers = {}
  for i = #sprite.layers, 1, -1 do
    local layer = sprite.layers[i]
    if is_export_layer(layer) then
      export_layers[layer.name] = layer
    end
  end
  return export_layers
end

-------------------------------------------
-- main function
-------------------------------------------
function update_export_all()
  local sprite = app.activeSprite
  local mm = MaskManager.Class(sprite)

  -- マスク対象エリアをマスク
  mm:UpdateAll()

  app.refresh()
end

function update_export_frame()
  local sprite = app.activeSprite
  local frame = app.activeFrame
  local mm = MaskManager.Class(sprite)

  -- マスク対象エリアをマスク
  mm:Update(frame.frameNumber)

  app.refresh()
end

function auto_sync_color()
  local sprite = app.activeSprite
  local mm = MaskManager.Class(sprite)

  -- マスク対象エリアをマスク
  mm:UpdateColor()

  app.refresh()
end

function set_export_layer()
  local sprite = app.activeSprite
  local mm = MaskManager.Class(sprite)

  -- 編集ダイアログの表示
  mm:EditorShow()

  app.refresh()
end

function set_export_layer_option()
  local layer = app.activeLayer
  if ExportLayer.Is(layer) then
    local ee = ExportLayer.Class(layer)
    ee:EditorShow()
  end
end

function unset_export_layer()
  local sprite = app.activeSprite
  local mm = MaskManager.Class(sprite)
  mm:Unset()
  app.refresh()
end




-------------------------------------------
--
-- create masked image data
--
-------------------------------------------

function update_all()
  app.transaction(
    function()
      local l = app.activeLayer
      local f = app.activeFrame 
      update_export_all()
      app.activeLayer = l
      app.activeFrame = f
    end
  )
end

function update_frame()
  app.transaction(
    function()
      local l = app.activeLayer
      local f = app.activeFrame 
      update_export_frame()
      app.activeLayer = l
      app.activeFrame = f
    end
  )
end

function synccolor()
  app.transaction(
    function()
      auto_sync_color()
    end
  )
end

function setmask()
  app.transaction(
    function()
      set_export_layer()
    end
  )
end

function unsetmask()
  app.transaction(
    function()
      unset_export_layer()
    end
  )
end

function editexport()
  app.transaction(
    function()
      set_export_layer_option()
    end
  )
end

function createmask()
  app.alert("NO IMPLEMNT")
end

local dlg = Dialog("dMask Toolbar")
dlg
  :label{text="Refresh"}
  :button{text="Active Frame", onclick=update_frame}
  :button{text="All", onclick=update_all}
  :newrow()
  :button{text="Sync Color", onclick=synccolor}
  :newrow()
  :separator()
  :label{text="Mask Layer"}
  :button{text="Set Mask", onclick=setmask}
  :button{text="Unset Mask", onclick=unsetmask}
  :newrow()
  :button{text="Create New Mask", onclick=createmask}
  :newrow()
  :separator()
  :label{text="Export Layer"}
  :button{text="Setting", onclick=editexport}
  :show{wait=false}
