dofile("./common.lua")
dofile("./meta_data.lua")
dofile("./meta_data_dialog.lua")
dofile("./auto-merge.lua")
dofile("./loop-extending.lua")
dofile("./merge-down-only-selected.lua")

function init(plugin)
    plugin:newCommand{
      id="toAutoMerge",
      title="Auto Merge",
      group="cel_popup_new",
      onclick=AutoMerge
    }
    plugin:newCommand{
      id="toSelectTargetLayer",
      title="Auto Select",
      group="cel_popup_new",
      onclick=SelectTargetLayer
    }
    
    plugin:newCommand{
      id="toLoopExtending",
      title="Loop Extending",
      group="sprite_crop",
      onclick=LoopExtending
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
      id="toEditCelMetaDataDialogShow",
      title="Mask Options(Cel)",
      group="cel_popup_new",
      onclick=EditCelMetaDataDialogShow
    }

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
end
  
function exit(plugin)
end