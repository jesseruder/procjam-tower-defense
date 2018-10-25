MAP_BLANK=0
MAP_PATH=1

function love.load()
    local width, height, flags = love.window.getMode()
    screenWidth = width
    screenHeight = height
    screenSize = width > height and height or width
    numBlocks = 10
    blockSize = screenSize / numBlocks
    lineSize = 3
    numEnemies = 10

    math.randomseed(os.time())
    reset()
end

function reset()
    lastX = -1
    lastY = -1
    depth = -1
    enemies = {}
    for i=0, numEnemies do
        enemies[i] = {
            x = 0,
            y = 0,
            startTime = math.random() * 5,
            dx = 1,
            dy = 0,
            visited = {}
        }
    end

    for i=0, 3 do
        depth = newLevel()
        if depth > 12 then
            break
        end
    end

    for i=0, 3 do
        depth = newLevel()
        if depth > 8 then
            break
        end
    end

    if depth == -1 then
        for i=0, 6 do
            depth = newLevel()
            if depth > 0 then
                break
            end
        end
    end
end

function newLevel()
    map = {}
    for x=0, numBlocks-1 do
        map[x] = {}
        for y=0, numBlocks - 1 do
            map[x][y] = MAP_BLANK
        end
    end

    map[0][numBlocks / 2] = MAP_PATH
    return drawPath(0, numBlocks / 2, 0, 0, 0)
end

function drawPath(x, y, lastDx, lastDy, depth)
    if depth > 20 then
        return -1
    end

    ox = x
    oy = y
    dir = math.random()
    dx = 0
    dy = 0
    if dir < 0.1 then
        dx = -1
    elseif dir < 0.4 then
        dy = -1
    elseif dir < 0.7 then
        dx = 1
    else
        dy = 1
    end

    if (lastDx ~= 0 and dx ~= 0) or (lastDy ~= 0 and dy ~= 0) then
        return drawPath(x, y, lastDx, lastDy, depth)
    end

    dist = math.floor(math.random() * 3) + 1
    for i=0, dist do
        x = x + dx
        y = y + dy

        if x < 0 then
            x = 0
            return drawPath(x, y, dx, dy, depth + 1)
        elseif x == numBlocks then
            return depth
        elseif y < 0 then
            y = 0
            return drawPath(x, y, dx, dy, depth + 1)
        elseif y == numBlocks then
            y = numBlocks - 1
            return drawPath(x, y, dx, dy, depth + 1)
        end
        
        if map[x][y] == MAP_PATH then
            return drawPath(ox, oy, 0, 0, depth + 1)
        end
        lastX = x
        lastY = y
        map[x][y] = MAP_PATH
    end

    return drawPath(x, y, dx, dy, depth + 1)
end

function love.draw()
    love.graphics.setColor(1, 0, 0, 1)

    for x = 0, numBlocks, 1
    do
        love.graphics.line(x * blockSize, 0, x * blockSize, screenSize)
    end
    
    for y = 0, numBlocks, 1
    do
        love.graphics.line(0, y * blockSize, screenSize, y * blockSize)
    end

    love.graphics.setColor(1, 0, 1, 1)
    for x=0, numBlocks-1 do
        for y=0, numBlocks - 1 do
            if map[x][y] == MAP_PATH then
                love.graphics.rectangle("fill", x * blockSize + lineSize, y * blockSize + lineSize, blockSize - lineSize * 2, blockSize - lineSize * 2)
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    for i=0, numEnemies do
        enemy = enemies[i]
        if enemy.startTime <= 0 then
            love.graphics.circle("fill", enemy.x, enemy.y, 10)
        end
    end
end

function love.keypressed(key, scancode, isrepeat)

end

function love.keyreleased(key, scancode)

end

function love.update(dt)
    for i=0, numEnemies do
        enemy = enemies[i]
        if enemy.startTime > 0 then
            enemy.startTime = enemy.startTime - dt
        else

        end
    end
end