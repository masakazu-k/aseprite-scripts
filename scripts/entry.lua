dofile("./common.lua")
dofile("./meta_data.lua")
dofile("./auto-merge.lua")
dofile("./loop-extending.lua")
dofile("./merge-down-only-selected.lua")
dofile("./meta_data_dialog.lua")

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
  -- Layer Menu
  ------------------------------------------------------------------------------
  plugin:newCommand{
    id="toAutoMergeLayer",
    title="-> Auto Mask (Copy & Paste)",
    group="layer_popup_new",
    onclick=AutoMerge
  }

  plugin:newCommand{
    id="toSaveCelsOffsetLayer",
    title="-> Store Offset",
    group="layer_popup_new",
    onclick=SaveCelsOffset
  }

  ------------------------------------------------------------------------------
  -- Cel Menu
  ------------------------------------------------------------------------------
  plugin:newCommand{
    id="toAutoMerge",
    title="-> Auto Mask (Copy & Paste)",
    group="cel_popup_new",
    onclick=AutoMerge
  }

  plugin:newCommand{
    id="toSelectTargetLayer",
    title="-> Auto Mask (Only Select)",
    group="cel_popup_new",
    onclick=SelectTargetLayer
  }

  plugin:newCommand{
    id="toSaveCelsOffset",
    title="-> Store Offset",
    group="cel_popup_new",
    onclick=SaveCelsOffset
  }

  plugin:newCommand{
    id="toLockUnlockCels",
    title="-> Lock/Unlock Merge",
    group="cel_popup_new",
    onclick=LockUnlockCels
  }

  plugin:newCommand{
    id="toMergeDownOnlySelected",
    title="Merge Down(Selected)",
    group="cel_popup_new",
    onclick=MergeDownOnlySelectedCels
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
end
  
function exit(plugin)
end