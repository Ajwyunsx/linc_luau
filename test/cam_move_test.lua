-- 模拟 camMove.lua 测试脚本
local xx, yy, xx2, yy2
local char = "dad"
local ofs = 45
local followchars = true

print("Script loaded, testing functions...")

function onCreate()
    print("onCreate called")
    
    -- Test if functions are available
    if getMidpointX then
        print("✓ getMidpointX is available")
    else
        print("✗ getMidpointX is nil!")
    end
    
    if getProperty then
        print("✓ getProperty is available")
    else
        print("✗ getProperty is nil!")
    end
    
    if triggerEvent then
        print("✓ triggerEvent is available")
    else
        print("✗ triggerEvent is nil!")
    end
end

function onUpdate(elapsed)
    -- 这些函数现在应该可用
    xx = getMidpointX("dad") + 150
    yy = getMidpointY("dad") - 100
    
    if followchars == true then
        if char == "dad" then
            local animName = getProperty('dad.animation.curAnim.name')
            if animName == 'singLEFT' then
                triggerEvent('Camera Follow Pos', xx-ofs, yy)
            end
        end
    end
end

print("Script functions registered!")
