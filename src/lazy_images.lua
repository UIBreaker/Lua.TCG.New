local Images={}
function Images.install(target,paths)
    setmetatable(target,{__index=function(cache,key)
        local path=paths[key];if not path then return nil end
        local image
        if love.filesystem.getInfo(path) then
            local ok,value=pcall(love.graphics.newImage,path)
            if ok then image=value;image:setFilter('linear','linear') end
        end
        rawset(cache,key,image or false)
        return image
    end})
    return target
end
return Images
