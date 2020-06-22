dofile("./common.lua")
dofile("./meta_data.lua")
dofile("./auto-merge.lua")
dofile("./link-cel.lua")
dofile("./loop-extending.lua")
dofile("./merge-down-only-selected.lua")
dofile("./meta_data_dialog.lua")

dofile("./menu.lua")

function init(plugin)
  
  ------------------------------------------------------------------------------
  -- Top Menu
  ------------------------------------------------------------------------------
  plugin:newCommand{
    id="toLoopExtending",
    title="Loop Extending",
    group="sprite_crop",
    onclick=LoopExtending
  }
  
  ------------------------------------------------------------------------------
  -- Dialogs
  ------------------------------------------------------------------------------
  plugin:newCommand{
    id="toCreateLayerMetaDataDialogShow",
    title="New Mask Layer",
    group="layer_popup_new",
    onclick=CreateLayerMetaDataDialogShow
  }

  plugin:newCommand{
    id="toEditLayerMetaDataDialogShow",
    title="Mask Options",
    group="layer_popup_new",
    onclick=EditLayerMetaDataDialogShow
  }
  
  plugin:newCommand{
    id="toEditCelMetaDataDialogShow",
    title="Mask Options (Cel)",
    group="cel_popup_new",
    onclick=EditCelMetaDataDialogShow
  }

  ------------------------------------------------------------------------------
  -- Layer Menu
  ------------------------------------------------------------------------------
  -- Mask and Link(Src/Dst) Cel Menu
  plugin:newCommand{
    id="toUpdate_layer",
    title="Update (Copy & Paste)",
    group="layer_popup_new",
    onclick=UpdateAll
  }

  plugin:newCommand{
    id="toStore_layer",
    title="Store Offset",
    group="layer_popup_new",
    onclick=StoreAll
  }

  ------------------------------------------------------------------------------
  -- Cel Menu
  ------------------------------------------------------------------------------
  -- Mask and Link(Src/Dst) Cel Menu
  plugin:newCommand{
    id="toUpdate_cel",
    title="Update (Copy & Paste)",
    group="cel_popup_new",
    onclick=UpdateSelected
  }

  plugin:newCommand{
    id="toStore_cel",
    title="Store Offset",
    group="cel_popup_new",
    onclick=StoreSelected
  }

  -- Mask Menu
  plugin:newCommand{
    id="toSelectTargetLayer",
    title="-> Auto Mask (Only Select)",
    group="cel_popup_new",
    onclick=SelectTargetLayer
  }

  plugin:newCommand{
    id="toLockUnlockCels",
    title="-> Lock/Unlock Merge",
    group="cel_popup_new",
    onclick=LockUnlockCels
  }

  plugin:newCommand{
    id="toCreateMaskCels",
    title="-> Create Mask",
    group="cel_popup_new",
    onclick=CreateMaskCels
  }

  -- Link(Src/Dst) Cel Menu
  plugin:newCommand{
    id="toCreateDstCels",
    title="Set Source Cel",
    group="cel_popup_new",
    onclick=CreateDstCels
  }

  plugin:newCommand{
    id="toCreateDstCelsAndUnlink",
    title="Set Source Cel(and UnLink)",
    group="cel_popup_new",
    onclick=CreateDstCelsAndUnlink
  }

  -- Other Cel Menu
  plugin:newCommand{
    id="toMergeDownOnlySelected",
    title="Merge Down(Selected)",
    group="cel_popup_new",
    onclick=MergeDownOnlySelectedCels
  }
end
  
function exit(plugin)
end