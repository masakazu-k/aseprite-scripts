dofile("./common.lua")
dofile("./auto-marge.lua")
dofile("./loop-extending.lua")

function init(plugin)
    plugin:newCommand{
      id="toAutoMarge",
      title="Auto Marge",
      group="cel_popup_new",
      onclick=AutoMarge
    }
    
    plugin:newCommand{
      id="toLoopExtending",
      title="Loop Extending",
      group="cel_popup_new",
      onclick=LoopExtending
    }
end
  
function exit(plugin)
end