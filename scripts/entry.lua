dofile("./common.lua")
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
end
  
function exit(plugin)
end