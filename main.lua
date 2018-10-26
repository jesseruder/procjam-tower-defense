MAP_BLANK=0
MAP_PATH=1
MAP_TOWER=2
MAP_TREE=3
MAP_BLOCKED_PATH=4

STATUS_BLOCKED="blocked"
UPGRADE_SPEED="speed"
UPGRADE_SPEED_PRICE=50
UPGRADE_RANGE="range"
UPGRADE_RANGE_PRICE=100
UPGRADE_POWER="power"
UPGRADE_POWER_PRICE=200

BLANK_PERCENTAGE=0.5

TOWER_PRICE=100
CLEAR_TREE_PRICE=50
BLOCK_PATH_PRICE=150

GAME_STATE_WAITING_TO_START=0
GAME_STATE_RUNNING=1
GAME_STATE_BETWEEN_ROUNDS=2
GAME_STATE_END=3

MIN_MONEY_TO_CONTINUE = 100

HEALTH_BAR_WIDTH = 20
HEALTH_BAR_HEIGHT = 5
HEALTH_BAR_Y = -20

PURCHASE_MENU_ROW_HEIGHT = 30
PURCHASE_MENU_WIDTH = 170
PURCHASE_MENU_FONT_SIZE = 12
PURCHASE_MENU_CANCEL_DIST = 200

function love.load()
    local width, height, flags = love.window.getMode()
    textHeight = 40
    screenWidth = width
    screenHeight = height - textHeight
    screenSize = screenWidth > screenHeight and screenHeight or screenWidth
    numBlocks = 10
    blockSize = screenSize / numBlocks
    lineSize = 3
    numEnemies = 20
    gameState = GAME_STATE_WAITING_TO_START
    font = love.graphics.newFont(14)
    menuFont = love.graphics.newFont(12)

    math.randomseed(os.time())
    reset(true)
end

function resetEnemy()
    enemy = {
        x = -0.5,
        y = (math.floor(numBlocks / 2) + 0.5) * blockSize,
        dx = 1,
        dy = 0,
        health = 20,
        maxHealth = 20,
        newDirectionDecided = false,
        lastBlock = false,
        speed = 60,
        active = false,
        scoreKill = 20,
        scoreLose = -200,
        spawnRate = 0.05,
        visited = {}
    }
    for j=0, numBlocks do
        enemy.visited[j] = {}
        for k=0, numBlocks do
            enemy.visited[j][k] = false
        end
    end
    return enemy
end

TOWER_WAITING = 0
TOWER_ATTACKING = 1
function newTower(x, y)
    map[x][y] = MAP_TOWER
    towers[numTowers] = {
        x = (x + 0.5) * blockSize,
        y = (y + 0.5) * blockSize,
        state = TOWER_WAITING,
        damage = 10,
        timeRemaining = 1,
        attackTime = 1,
        waitTime = 1,
        range = blockSize * 2.5,
        enemyId = -1
    }
    mapMetadata[x][y].tower = towers[numTowers]
    numTowers = numTowers + 1
end

function reset(newGame)
    if newGame then
        money = 300
        levels = 1
    else
        levels = levels + 1
    end
    purchaseMenu = nil
    lastX = -1
    lastY = -1
    depth = -1
    enemies = {}
    towers = {}
    numTowers = 0
    time = 60
    for i=0, numEnemies do
        enemies[i] = resetEnemy(enemy)
    end
    enemies[0].active = true

    mapMetadata = {}
    for x=0, numBlocks-1 do
        mapMetadata[x] = {}
        for y=0, numBlocks - 1 do
            mapMetadata[x][y] = {}
        end
    end

    -- try generating a good level
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

    -- fill in trees
    local mapCopy = {}
    for x=0, numBlocks-1 do
        mapCopy[x] = {}
        for y=0, numBlocks - 1 do
            mapCopy[x][y] = 0
            if map[x][y] == MAP_PATH then
                mapCopy[x][y] = 1
            end
        end
    end

    blurMap(mapCopy, 1)
    blurMap(mapCopy, 2)

    for x=0, numBlocks-1 do
        for y=0, numBlocks - 1 do
            if mapCopy[x][y] == 0 then
                if map[x][y] == MAP_BLANK then
                    map[x][y] = MAP_TREE
                end
            end
        end
    end
end

function blurMap(mapCopy, startingNumber)
    for x=0, numBlocks-1 do
        for y=0, numBlocks - 1 do
            if mapCopy[x][y] == startingNumber then
                for xx=x-1, x+1 do
                    for yy=y-1, y+1 do
                        if xx >= 0 and yy >= 0 and xx < numBlocks and yy < numBlocks then
                            mapCopy[xx][yy] = startingNumber + 1
                        end
                    end
                end
            end
        end
    end
end

function newLevel()
    map = {}
    for x=0, numBlocks-1 do
        map[x] = {}
        for y=0, numBlocks - 1 do
            map[x][y] = MAP_TREE
        end
    end

    for i=0, numBlocks*numBlocks*BLANK_PERCENTAGE do
        map[math.floor(math.random() * numBlocks)][math.floor(math.random() * numBlocks)] = MAP_BLANK
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
            if y > 0 and y < numBlocks - 1 then
                return depth
            else
                x = numBlocks - 1
                return drawPath(x, y, dx, dy, depth + 1)
            end
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
    love.graphics.setFont(font)
    love.graphics.push()
    love.graphics.clear(0.7, 0.7, 0.7, 1)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Time: " .. math.floor(time + 0.5), 20, 10)
    love.graphics.print("$" .. money, screenSize - 100, 10)

    love.graphics.translate(0, textHeight)
    love.graphics.setColor(1, 0, 0, 1)

    love.graphics.setLineWidth(1)
    for x = 0, numBlocks, 1
    do
        love.graphics.line(x * blockSize, 0, x * blockSize, screenSize)
    end
    
    for y = 0, numBlocks, 1
    do
        love.graphics.line(0, y * blockSize, screenSize, y * blockSize)
    end

    -- path
    for x=0, numBlocks-1 do
        for y=0, numBlocks - 1 do
            if map[x][y] == MAP_PATH or map[x][y] == MAP_BLOCKED_PATH then
                love.graphics.setColor(1, 0, 1, 1)
                love.graphics.rectangle("fill", x * blockSize + lineSize, y * blockSize + lineSize, blockSize - lineSize * 2, blockSize - lineSize * 2)
            end

            if map[x][y] == MAP_BLOCKED_PATH and mapMetadata[x][y].flashOn then
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.rectangle("fill", x * blockSize + lineSize, y * blockSize + lineSize, blockSize - lineSize * 2, blockSize - lineSize * 2)
            end
        end
    end

    -- tree
    love.graphics.setColor(34/256, 139/256, 34/256, 1)
    for x=0, numBlocks-1 do
        for y=0, numBlocks - 1 do
            if map[x][y] == MAP_TREE then
                love.graphics.rectangle("fill", x * blockSize + lineSize, y * blockSize + lineSize, blockSize - lineSize * 2, blockSize - lineSize * 2)
            end
        end
    end

    -- towers
    love.graphics.setColor(0, 0, 1, 1)
    for x=0, numBlocks-1 do
        for y=0, numBlocks - 1 do
            if map[x][y] == MAP_TOWER then
                love.graphics.rectangle("fill", x * blockSize + lineSize, y * blockSize + lineSize, blockSize - lineSize * 2, blockSize - lineSize * 2)
            end
        end
    end

    -- bullets
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.setLineWidth(4)
    if gameState == GAME_STATE_RUNNING then
        for i=0, numTowers - 1 do
            local tower = towers[i]
            if tower.enemyId > -1 then
                enemy = enemies[tower.enemyId]
                if enemy.active then
                    love.graphics.line(tower.x, tower.y, enemy.x, enemy.y)
                end
            end
        end
    end

    -- enemies
    love.graphics.setColor(1, 1, 1, 1)
    if gameState == GAME_STATE_RUNNING then
        for i=0, numEnemies do
            local enemy = enemies[i]
            if enemy.active then
                love.graphics.setColor(0.7, 0.7, 1, 1)
                love.graphics.circle("fill", enemy.x, enemy.y, 10)

                if enemy.health < enemy.maxHealth then
                    local healthPercent = enemy.health / enemy.maxHealth
                    love.graphics.setColor(0.2, 0.2, 0.2, 1)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", enemy.x - HEALTH_BAR_WIDTH / 2.0, enemy.y + HEALTH_BAR_Y, HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.rectangle("fill", enemy.x - HEALTH_BAR_WIDTH / 2.0, enemy.y + HEALTH_BAR_Y, HEALTH_BAR_WIDTH * healthPercent, HEALTH_BAR_HEIGHT)
                    love.graphics.setColor(1, 0, 0, 1)
                    love.graphics.rectangle("fill", enemy.x - HEALTH_BAR_WIDTH / 2.0 + HEALTH_BAR_WIDTH * healthPercent, enemy.y + HEALTH_BAR_Y, HEALTH_BAR_WIDTH * (1.0 - healthPercent), HEALTH_BAR_HEIGHT)
                end
            end
        end
    end

    love.graphics.pop()

    -- purchase menu
    if gameState == GAME_STATE_RUNNING and purchaseMenu then
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", purchaseMenu.x, purchaseMenu.y, PURCHASE_MENU_WIDTH, PURCHASE_MENU_ROW_HEIGHT * purchaseMenu.numItems)
        
        for i=0, purchaseMenu.numItems - 1 do
            if purchaseMenu.items[i + 1].focus then
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end

            if purchaseMenu.items[i + 1].price > money then
                love.graphics.setColor(1, 0, 0, 1)
            end
            love.graphics.rectangle("fill", purchaseMenu.x, purchaseMenu.y + PURCHASE_MENU_ROW_HEIGHT * i, PURCHASE_MENU_WIDTH, PURCHASE_MENU_ROW_HEIGHT)
        end

        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.setLineWidth(1)
        for i=1, purchaseMenu.numItems - 1 do
            love.graphics.line(purchaseMenu.x, purchaseMenu.y + i * PURCHASE_MENU_ROW_HEIGHT, purchaseMenu.x + PURCHASE_MENU_WIDTH, purchaseMenu.y + i * PURCHASE_MENU_ROW_HEIGHT)
        end

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(menuFont)
        for i=0, purchaseMenu.numItems - 1 do
            love.graphics.print(purchaseMenu.items[i + 1].title .. "($" .. purchaseMenu.items[i + 1].price .. ")", purchaseMenu.x + 10, purchaseMenu.y + (i + 0.5) * PURCHASE_MENU_ROW_HEIGHT - PURCHASE_MENU_FONT_SIZE / 2)
        end
    end

    -- overlay
    if gameState ~= GAME_STATE_RUNNING then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.rectangle("fill", 0, 0, screenSize + 1, screenSize + textHeight)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(font)
        text = ""
        if gameState == GAME_STATE_BETWEEN_ROUNDS then
            text = "Click to continue to the next level!"
        elseif gameState == GAME_STATE_END then
            text = "You made it to level " .. levels .. "! But ran out of money... Click to restart"
        elseif gameState == GAME_STATE_WAITING_TO_START then
            text = "Click anywhere to start! Click on tiles to purchase upgrades"
        end

        love.graphics.print(text, screenSize / 2 - 200, screenSize / 2 - 10)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if purchaseMenu == nil then
        return
    end

    for i=0, purchaseMenu.numItems - 1 do
        purchaseMenu.items[i + 1].focus = false
    end

    if x > purchaseMenu.x and x < purchaseMenu.x + PURCHASE_MENU_WIDTH and y > purchaseMenu.y and y < purchaseMenu.y + PURCHASE_MENU_ROW_HEIGHT * purchaseMenu.numItems then
        local itemId = math.floor((y - purchaseMenu.y) / PURCHASE_MENU_ROW_HEIGHT)
        purchaseMenu.items[itemId + 1].focus = true
    end

    local centerX = purchaseMenu.x + PURCHASE_MENU_WIDTH / 2
    local centerY = purchaseMenu.y + PURCHASE_MENU_ROW_HEIGHT * (purchaseMenu.numItems / 2.0)
    local distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2))
    if distance > PURCHASE_MENU_CANCEL_DIST then
        purchaseMenu = nil
    end
end

function love.mousepressed(x, y, button, istouch)
    if button ~= 1 then
        return
    end

    if gameState == GAME_STATE_WAITING_TO_START then
        gameState = GAME_STATE_RUNNING
        return
    elseif gameState == GAME_STATE_BETWEEN_ROUNDS then
        reset(false)
        gameState = GAME_STATE_RUNNING
        return
    elseif gameState == GAME_STATE_END then
        reset(true)
        gameState = GAME_STATE_RUNNING
        return
    elseif gameState ~= GAME_STATE_RUNNING then
        return
    end

    if purchaseMenu then
        if x > purchaseMenu.x and x < purchaseMenu.x + PURCHASE_MENU_WIDTH and y > purchaseMenu.y and y < purchaseMenu.y + PURCHASE_MENU_ROW_HEIGHT * purchaseMenu.numItems then
            local itemId = math.floor((y - purchaseMenu.y) / PURCHASE_MENU_ROW_HEIGHT)
            local item = purchaseMenu.items[itemId + 1]
            if money >= item.price then
                money = money - item.price
                item.action(purchaseMenu.blockX, purchaseMenu.blockY)
            else
                return
            end
        end

        purchaseMenu = nil
        return
    end
    
    blockX = math.floor(x * numBlocks / screenSize)
    blockY = math.floor((y - textHeight) * numBlocks / screenSize)

    if blockX < 0 or blockY < 0 or blockX >= numBlocks or blockY >= numBlocks then
        return
    end

    purchaseMenu = {
        x = x - PURCHASE_MENU_ROW_HEIGHT / 2,
        y = y - PURCHASE_MENU_ROW_HEIGHT / 2,
        blockX = blockX,
        blockY = blockY,
        numItems = 0
    }

    local type = map[blockX][blockY]
    local metadata = mapMetadata[blockX][blockY]
    if type == MAP_BLANK then
        purchaseMenu.numItems = 1
        purchaseMenu.items = {
            {
                title = "Purchase Tower",
                price = TOWER_PRICE,
                action = newTower
            }
        }
    elseif type == MAP_PATH then
        purchaseMenu.numItems = 1
        purchaseMenu.items = {
            {
                title = "Block Temporarily",
                price = BLOCK_PATH_PRICE,
                action = function (x, y)
                    map[x][y] = MAP_BLOCKED_PATH
                    mapMetadata[x][y] = {
                        status = STATUS_BLOCKED,
                        timeRemaining = 10,
                        flashTimeRemaining = 0.1,
                        flashTime = 0.1,
                        flashOn = true
                    }
                end
            }
        }
    elseif type == MAP_TOWER then
        purchaseMenu.items = {}

        if not metadata[UPGRADE_SPEED] then
            purchaseMenu.numItems = purchaseMenu.numItems + 1
            purchaseMenu.items[purchaseMenu.numItems] = {
                title = "Speed Upgrade",
                price = UPGRADE_SPEED_PRICE,
                action = function (x, y)
                    mapMetadata[x][y][UPGRADE_SPEED] = true
                    mapMetadata[x][y].tower.waitTime = 0.1
                end
            }
        end

        if not metadata[UPGRADE_RANGE] then
            purchaseMenu.numItems = purchaseMenu.numItems + 1
            purchaseMenu.items[purchaseMenu.numItems] = {
                title = "Range Upgrade",
                price = UPGRADE_RANGE_PRICE,
                action = function (x, y)
                    mapMetadata[x][y][UPGRADE_RANGE] = true
                    mapMetadata[x][y].tower.range = mapMetadata[x][y].tower.range * 2
                end
            }
        end

        if not metadata[UPGRADE_POWER] then
            purchaseMenu.numItems = purchaseMenu.numItems + 1
            purchaseMenu.items[purchaseMenu.numItems] = {
                title = "Power Upgrade",
                price = UPGRADE_POWER_PRICE,
                action = function (x, y)
                    mapMetadata[x][y][UPGRADE_POWER] = true
                    mapMetadata[x][y].tower.damage = mapMetadata[x][y].tower.damage * 3
                end
            }
        end

    elseif type == MAP_TREE then
        purchaseMenu.numItems = 1
        purchaseMenu.items = {
            {
                title = "Clear Tree",
                price = CLEAR_TREE_PRICE,
                action = function (x, y) map[x][y] = MAP_BLANK end
            }
        }
    end

    if purchaseMenu.numItems > 0 then
        purchaseMenu.items[1].focus = true
    else
        purchaseMenu = nil
    end
end

function love.keypressed(key, scancode, isrepeat)

end

function love.keyreleased(key, scancode)

end

function love.update(dt)
    if gameState ~= GAME_STATE_RUNNING then
        return
    end

    time = time - dt
    if time <= 0 then
        time = 0
        if money >= MIN_MONEY_TO_CONTINUE then
            gameState = GAME_STATE_BETWEEN_ROUNDS
        else
            gameState = GAME_STATE_END
        end
    end

    for i=0, numEnemies do
        enemy = enemies[i]
        if enemy.active then
            enemyMove(dt, enemy)
        else
            if math.random() < dt * enemy.spawnRate then
                enemies[i] = resetEnemy()
                enemy = enemies[i]
                enemy.active = 0
            end
        end
    end

    for i=0, numTowers - 1 do
        updateTower(dt, towers[i])
    end

    for x=0, numBlocks-1 do
        for y=0, numBlocks - 1 do
            local m = mapMetadata[x][y]
            if m and m.status == STATUS_BLOCKED then
                m.timeRemaining = m.timeRemaining - dt
                if m.timeRemaining < 0 then
                    mapMetadata[x][y] = {}
                    map[x][y] = MAP_PATH
                else
                    m.flashTimeRemaining = m.flashTimeRemaining - dt
                    if m.flashTimeRemaining < 0 then
                        m.flashOn = not m.flashOn
                        m.flashTimeRemaining = m.flashTime
                    end
                end
            end
        end
    end
end


function updateTower(dt, tower)
    tower.timeRemaining = tower.timeRemaining - dt

    if tower.state == TOWER_WAITING then
        if tower.timeRemaining < 0 then
            towerLockOnToEnemy(tower)
            if tower.enemyId > -1 then
                tower.state = TOWER_ATTACKING
                tower.timeRemaining = tower.attackTime
            end
        end
    elseif tower.state == TOWER_ATTACKING then
        local enemy = enemies[tower.enemyId]
        if enemy.active then
            enemy.health = enemy.health - dt * tower.damage

            local distance = math.sqrt(math.pow(enemy.x - tower.x, 2) + math.pow(enemy.y - tower.y, 2))
            if distance > tower.range then
                tower.timeRemaining = -1
            end

            if enemy.health < 0 then
                enemy.active = false
                updateScore(enemy.scoreKill)
            end

            if tower.timeRemaining < 0 or not enemy.active then
                tower.state = TOWER_WAITING
                tower.timeRemaining = tower.waitTime
                tower.enemyId = -1
            end
        else
            tower.state = TOWER_WAITING
            tower.timeRemaining = tower.waitTime
            tower.enemyId = -1
        end
    end
end

function towerLockOnToEnemy(tower)
    local minDistance = 10000000000
    for i=0, numEnemies do
        local enemy = enemies[i]
        if enemy.active then
            local distance = math.sqrt(math.pow(enemy.x - tower.x, 2) + math.pow(enemy.y - tower.y, 2))

            if distance < minDistance then
                minDistance = distance
            end
        end
    end

    if minDistance < tower.range then
        for i=0, numEnemies do
            local enemy = enemies[i]
            if enemy.active then
                local distance = math.sqrt(math.pow(enemy.x - tower.x, 2) + math.pow(enemy.y - tower.y, 2))
                
                if math.abs(distance - minDistance) < 0.001 then
                    tower.enemyId = i
                    return
                end
            end
        end
    end
end


function updateScore(amount)
    money = money + amount
end


-- dumb enemy movement
function enemyMove(dt, enemy)
    enemy.x = enemy.x + enemy.dx * dt * enemy.speed
    enemy.y = enemy.y + enemy.dy * dt * enemy.speed

    if enemy.x > screenSize then
        enemy.active = false
        updateScore(enemy.scoreLose)
    end

    currentBlockX = math.floor(enemy.x * numBlocks / screenSize)
    currentBlockY = math.floor(enemy.y * numBlocks / screenSize)

    if currentBlockX >= 0 and currentBlockX < numBlocks and currentBlockY >= 0 and currentBlockY < numBlocks then
        enemy.visited[currentBlockX][currentBlockY] = true
    end

    choosingNewDirection = false
    if enemy.dx > 0 then
        if enemy.x - (currentBlockX * blockSize) > blockSize * 0.5 then
            if not enemy.newDirectionDecided then
                choosingNewDirection = true
            end
        else
            enemy.newDirectionDecided = false
        end
    end

    if enemy.dx < 0 then
        if enemy.x - (currentBlockX * blockSize) < blockSize * 0.5 then
            if not enemy.newDirectionDecided then
                choosingNewDirection = true
            end
        else
            enemy.newDirectionDecided = false
        end
    end

    if enemy.dy > 0 then
        if enemy.y - (currentBlockY * blockSize) > blockSize * 0.5 then
            if not enemy.newDirectionDecided then
                choosingNewDirection = true
            end
        else
            enemy.newDirectionDecided = false
        end
    end

    if enemy.dy < 0 then
        if enemy.y - (currentBlockY * blockSize) < blockSize * 0.5 then
            if not enemy.newDirectionDecided then
                choosingNewDirection = true
            end
        else
            enemy.newDirectionDecided = false
        end
    end

    if choosingNewDirection then
        enemy.newDirectionDecided = true
        oldDx = enemy.dx
        oldDy = enemy.dy

        -- if at last block just go right
        if currentBlockX == lastX and currentBlockY == lastY then
            enemy.dx = 1
            enemy.dy = 0
            enemy.lastBlock = true
            return
        end

        -- 20 chances to find a random direction that hasn't been visited
        for i=0, 20 do
            dir = math.random()
            enemy.dx = 0
            enemy.dy = 0
            if dir < 0.25 then
                enemy.dx = -1
            elseif dir < 0.5 then
                enemy.dy = -1
            elseif dir < 0.75 then
                enemy.dx = 1
            else
                enemy.dy = 1
            end

            nextBlockX = currentBlockX + enemy.dx
            nextBlockY = currentBlockY + enemy.dy

            if nextBlockX >= 0 and nextBlockY >= 0 and nextBlockX < numBlocks and nextBlockY < numBlocks and map[nextBlockX][nextBlockY] == MAP_PATH and not enemy.visited[nextBlockX][nextBlockY] then
                return
            end
        end

        -- 20 chances to find a random direction even if it's visited
        for i=0, 20 do
            dir = math.random()
            enemy.dx = 0
            enemy.dy = 0
            if dir < 0.25 then
                enemy.dx = -1
            elseif dir < 0.5 then
                enemy.dy = -1
            elseif dir < 0.75 then
                enemy.dx = 1
            else
                enemy.dy = 1
            end

            if enemy.dx == -oldDx and enemy.dy == -oldDy then
                --ugh
            else
                nextBlockX = currentBlockX + enemy.dx
                nextBlockY = currentBlockY + enemy.dy

                if nextBlockX >= 0 and nextBlockY >= 0 and nextBlockX < numBlocks and nextBlockY < numBlocks and map[nextBlockX][nextBlockY] == MAP_PATH then
                    return
                end
            end
        end

        -- idk what happened, just choose something that's on the path
        for i=0, 4 do
            enemy.dx = 0
            enemy.dy = 0
            if i == 0 then
                enemy.dx = -1
            elseif i == 1 then
                enemy.dy = -1
            elseif i == 2 then
                enemy.dx = 1
            else
                enemy.dy = 1
            end

            nextBlockX = currentBlockX + enemy.dx
            nextBlockY = currentBlockY + enemy.dy

            if nextBlockX >= 0 and nextBlockY >= 0 and nextBlockX < numBlocks and nextBlockY < numBlocks and map[nextBlockX][nextBlockY] == MAP_PATH then
                return
            end
        end
    end
end