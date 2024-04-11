local posX, posY, posZ = 0, 0, 0
local facing = 0 -- 0 away from chest, 1 right, 2 towards chest, 3 left

function forward()
    while turtle.detect() do
        turtle.dig()
    end
    turtle.forward()
    if facing == 0 then
        posZ = posZ + 1
    elseif facing == 1 then
        posX = posX + 1
    elseif facing == 2 then
        posZ = posZ - 1
    elseif facing == 3 then
        posX = posX - 1
    end
end

function turnRight()
    turtle.turnRight()
    facing = facing + 1
    if facing > 3 then
        facing = 0
    end
end

function turnLeft()
    turtle.turnLeft()
    facing = facing - 1
    if facing < 0 then
        facing = 3
    end
end

function down()
    if turtle.detectDown() then
        turtle.digDown()
    end
    turtle.down()
    posY = posY - 1
end

function up()
    if turtle.detectUp() then
        turtle.digUp()
    end
    turtle.up()
    posY = posY + 1
end

function TurnTo(dir)
    while dir > facing do
        turnRight()
    end
    while dir < facing do
        turnLeft()
    end
end

function GoToX(x)
    deltaX = posX - x
    if deltaX == 0 then
        return
    end
    if deltaX < 0 then
        TurnTo(1)
        for i = 1, -deltaX do
            forward()
        end
    else
        TurnTo(3)
        for i = 1, deltaX do
            forward()
        end
    end
end

function GoToZ(z)
    deltaZ = posZ - z
    if deltaZ == 0 then
        return
    end
    if deltaZ < 0 then
        TurnTo(0)
        for i = 1, -deltaZ do
            forward()
        end
    else
        TurnTo(2)
        for i = 1, deltaZ do
            forward()
        end
    end
end

function GoToY(y)
    deltaY = posY - y
    if deltaY == 0 then
        return
    end
    if deltaY < 0 then
        for i = 1, -deltaY do
            up()
        end
    else
        for i = 1, deltaY do
            down()
        end
    end
end

function GoToYLast(x,y,z)
    GoToZ(z)
    GoToX(x)
    GoToY(y)
end

function GoToYFirst(x,y,z)
    GoToY(y)
    GoToX(x)
    GoToZ(z)
end

function MineMove()
    forward()
    turtle.digUp()
    turtle.digDown()
end

function MineRotate(row)
    if row % 2 == 0 then
        turnRight()
        MineMove()
        turnRight()
    else
        turnLeft()
        MineMove()
        turnLeft()
    end
end

function MineLevelDown()
    turnRight()
    turnRight()
    down()
    down()
    down()
    turtle.digDown()
end

function LowFuel()
    local fuel = turtle.getFuelLevel()
    local distanceHome = math.abs(posY) + math.abs(posX) + math.abs(posZ)
    return fuel < distanceHome + 100
end

function InventoryFull()
    local emptySpaces = 0
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            emptySpaces = emptySpaces + 1
        end
    end
    return emptySpaces < 2
end

function SaveProgress(size,height,x,y,z,facing)
    local file = fs.open("mineSettings", "w+")
    file.writeLine(size)
    file.writeLine(height)
    file.writeLine(x)
    file.writeLine(y)
    file.writeLine(z)
    file.writeLine(facing)
    file.close()
end

function DeleteProgress()
    fs.delete("mineSettings")
end

local mining = true
local pause = true

function ListenForPause()
    while true do
        local event, key, is_held = os.pullEvent("key")
        mining = false
        pause = true
    end
end

function MineProcess()
    term.clear()
    term.setCursorPos(1,1)

    local file = fs.open("mineSettings", "r")
    local size = tonumber(file.readLine())
    local height = tonumber(file.readLine())
    local x = tonumber(file.readLine())
    local y = tonumber(file.readLine())
    local z = tonumber(file.readLine())
    local dir = tonumber(file.readLine())
    file.close()

    print("Gehe zu Start Position...")
    GoToYLast(x,y,z)
    TurnTo(dir)

    print("Minen...")

    while mining do
        local reverse = posY % 6 ~= 0
        local layerNotDone = (not reverse and posX < size-1) or (reverse and posX > 0)

        if facing == 0 then
            if posZ < size then
                MineMove()
            else
                if layerNotDone then
                    MineRotate(posX)
                else
                    if posY > -height then
                        MineLevelDown()
                        reverse = not reverse
                    else
                        DeleteProgress()
                        pause = true
                        return
                    end
                end
            end
        elseif facing == 2 then
            if posZ > 1 then
                MineMove()
            else
                if layerNotDone then
                    MineRotate(posX)
                else
                    if posY > -height then
                        MineLevelDown()
                        reverse = not reverse
                    else
                        DeleteProgress()
                        pause = true
                        return
                    end
                end
            end
        end
        if LowFuel() then
            print("Tank fast Leer!")
            mining = false
            pause = true
        end
        if InventoryFull() then
            print("Inventar Voll!")
            mining = false
        end
    end
    SaveProgress(size, height, posX, posY, posZ, facing)
end


function StartNewMine()
    term.clear()
    local mineSize = 0
    local mineHeight = 0

    repeat
        term.setCursorPos(1,1)
        term.clearLine()
        term.write("Größe:")
        mineSize = tonumber(read())
    until (mineSize ~= nil)
    
    repeat
        term.setCursorPos(1,2)
        term.clearLine()
        term.write("Höhe:")
        mineHeight = tonumber(read())
    until (mineHeight ~= nil)

    SaveProgress(mineSize, mineHeight, 0,0,0,0)

    ContinueMine()
end

function ContinueMine()
    pause = false
    mining = true
    parallel.waitForAny(MineProcess,ListenForPause)
    print("Gehe nach Hause...")
    GoToYFirst(0,0,0)
end

function Refuel()
    for i = 1, 16 do
        turtle.select(i)
        if turtle.refuel(0) then
            turtle.refuel()
        end
    end
end

function DumpInventory()
    GoToYFirst(0,0,0)
    TurnTo(2)
    for i = 1, 16 do
        turtle.select(i)
        turtle.drop()
    end
    TurnTo(0)
end

function Exit()
    exit = true
end


local menu = {
    {"Start",myfunc = StartNewMine, avalible = true},
    {"Fortsetzen",myfunc = ContinueMine, avalible = true},
    {"Tanken",myfunc = Refuel, avalible = true},
    {"Inventar Leeren",myfunc = DumpInventory, avalible = true},
    {"Beenden",myfunc = Exit, avalible = true}
}

local selected = 1
local exit = false

function RedrawMenu()
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
    print("- BD Miner -")
    term.setCursorPos(1,2)
    local fuel = turtle.getFuelLevel()
    local fuelPercentage = math.floor((fuel / turtle.getFuelLimit()) * 100)
    print("Treibstoff: " .. fuelPercentage .. "%  (" .. fuel .. " Blöcke)")
    term.setCursorPos(1,4)
    for i = 1, #menu do
        if i == selected then
            term.setTextColor(colors.green)
        elseif not menu[i].avalible then
            term.setTextColor(colors.gray)
        else
            term.setTextColor(colors.white)
        end
        print(menu[i][1])
    end
end

function MainMenu()

    menu[2].avalible = fs.exists("mineSettings")

    RedrawMenu()
    local event, key, is_held = os.pullEvent("key")
    if not is_held then
        if key == keys.up then
            if selected > 1 then
                selected = selected - 1
            end
        elseif key == keys.down then
            if selected < #menu then
                selected = selected + 1
            end
        elseif key == keys.enter then
            if menu[selected].avalible then
                menu[selected].myfunc()
            end
        end
    end
end

while not exit do
    if pause then
        MainMenu()
    else
        DumpInventory()
        ContinueMine()
    end
end
