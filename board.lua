local Piece = require("piece")
local Rules = require("rules")

local board = {}

local HEX_RADIUS = 30
-- Для pointy-top гексагонів
local HEX_WIDTH = math.sqrt(3) * HEX_RADIUS
local HEX_HEIGHT = HEX_RADIUS * 2

local OFFSET_X, OFFSET_Y

board.tiles = {}
board.pieces = {}
board.selected = nil
board.possibleMoves = {}
board.currentPlayer = 1

function board.load()
    board.tiles = {}
    board.pieces = {}
    board.selected = nil
    board.possibleMoves = {}
    board.currentPlayer = 1

    -- Область поля (9x9 гексів, радіус 4)
    local min_q, max_q = -4, 4
    local min_r, max_r = -4, 4

    -- Створення клітинок
    for q = min_q, max_q do
        for r = math.max(min_r, -q - max_q), math.min(max_r, -q - min_q) do
            table.insert(board.tiles, {q = q, r = r})
        end
    end

    -- Обчислення справжніх розмірів поля для центрування
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge
    
    for _, tile in ipairs(board.tiles) do
        local x, y = axialToPixelRaw(tile.q, tile.r)
        min_x = math.min(min_x, x)
        max_x = math.max(max_x, x)
        min_y = math.min(min_y, y)
        max_y = math.max(max_y, y)
    end
    
    -- Центрування поля
    local field_width = max_x - min_x
    local field_height = max_y - min_y
    
    OFFSET_X = (love.graphics.getWidth() - field_width) / 2 - min_x
    OFFSET_Y = (love.graphics.getHeight() - field_height) / 2 - min_y

    -- Стартове розміщення фішок
    for _, tile in ipairs(board.tiles) do
        if tile.r <= -2 then
            table.insert(board.pieces, Piece.new(1, "normal", tile.q, tile.r))
        elseif tile.r >= 2 then
            table.insert(board.pieces, Piece.new(2, "normal", tile.q, tile.r))
        end
    end
end

function board.draw()
    for _, tile in ipairs(board.tiles) do
        local x, y = axialToPixel(tile.q, tile.r)
        
        -- Базовий колір клітинки
        love.graphics.setColor(0.8, 0.8, 0.8)
        drawHex(x, y, "line")
        
        -- Підсвічування вибраної клітинки білим
        if board.selected and board.selected.q == tile.q and board.selected.r == tile.r then
            love.graphics.setColor(1, 1, 1, 0.7)
            drawHex(x, y, "fill")
        end

        -- Підсвічування можливих ходів зеленим
        for _, move in ipairs(board.possibleMoves) do
            if move.q == tile.q and move.r == tile.r then
                love.graphics.setColor(0.2, 0.8, 0.2, 0.7)
                drawHex(x, y, "fill")
                break
            end
        end
    end

    -- Відновлення кольору для фішок
    love.graphics.setColor(1, 1, 1)
    for _, piece in ipairs(board.pieces) do
        piece:draw(axialToPixel)
    end
end

function board.mousepressed(x, y, button)
    local clickedQ, clickedR = pixelToAxial(x, y)
    
    -- Відладка кліків
    print("Клік в пікселях:", x, y)
    print("Конвертовано в аксіальні:", clickedQ, clickedR)

    if clickedQ and clickedR then
        -- Перевіряємо, чи клік потрапив на існуючу клітинку
        local validTile = false
        for _, tile in ipairs(board.tiles) do
            if tile.q == clickedQ and tile.r == clickedR then
                validTile = true
                break
            end
        end
        
        if not validTile then
            print("Клік поза межами поля")
            return
        end
        
        local piece = board.getPieceAt(clickedQ, clickedR)
        print("Фішка на клітинці:", piece and piece.player or "немає")

        if piece and piece.player == board.currentPlayer then
            print("Вибрано фішку гравця", piece.player)
            board.selected = piece

            if Rules.mustCapture(board.currentPlayer, board.pieces) then
                local moves = Rules.getValidMoves(piece, board.pieces)
                board.possibleMoves = {}
                for _, move in ipairs(moves) do
                    if move.capture then
                        table.insert(board.possibleMoves, move)
                    end
                end
            else
                board.possibleMoves = Rules.getValidMoves(piece, board.pieces)
            end
            print("Кількість можливих ходів:", #board.possibleMoves)

        elseif board.selected then
            print("Спроба походити на", clickedQ, clickedR)
            for _, move in ipairs(board.possibleMoves) do
                if move.q == clickedQ and move.r == clickedR then
                    print("Валідний хід знайдено")
                    local captured = move.capture
                    board.selected.q = move.q
                    board.selected.r = move.r

                    if captured then
                        Rules.removePieceAt(board.pieces, captured.q, captured.r)

                        local furtherMoves = Rules.getValidMoves(board.selected, board.pieces)
                        local hasMoreJumps = false
                        board.possibleMoves = {}
                        for _, m in ipairs(furtherMoves) do
                            if m.capture then
                                hasMoreJumps = true
                                table.insert(board.possibleMoves, m)
                            end
                        end

                        if hasMoreJumps then
                            return
                        end
                    end

                    -- Перетворення в "короля"
                    if board.currentPlayer == 1 and board.selected.r == 4 then
                        board.selected.kind = "king"
                    elseif board.currentPlayer == 2 and board.selected.r == -4 then
                        board.selected.kind = "king"
                    end

                    board.selected = nil
                    board.possibleMoves = {}
                    board.currentPlayer = 3 - board.currentPlayer
                    -- AI хід автоматично після гравця
                    --if board.currentPlayer == 2 then
                        --local ai = require("ai")
                        --ai.makeMove(board)
                    --end
                    print("Хід завершено, тепер ходить гравець", board.currentPlayer)
                    -- Перевірка завершення гри
                    board.checkGameOver()
                    return
                end
            end
            print("Хід недозволений")
        else
            print("Скинуто вибір")
            board.selected = nil
            board.possibleMoves = {}
        end
    else
        print("Неправильна конвертація координат")
    end
end

-- Пошук фішки на клітинці
function board.getPieceAt(q, r)
    for _, piece in ipairs(board.pieces) do
        if piece.q == q and piece.r == r then
            return piece
        end
    end
    return nil
end

-- Малювання шестикутника (pointy-top)
function drawHex(x, y, mode)
    mode = mode or "line"
    local points = {}
    for i = 0, 5 do
        local angle = math.rad(60 * i + 30)  -- +30 для pointy-top
        local px = x + HEX_RADIUS * math.cos(angle)
        local py = y + HEX_RADIUS * math.sin(angle)
        table.insert(points, px)
        table.insert(points, py)
    end
    love.graphics.polygon(mode, points)
end

-- Допоміжна функція для обчислення координат без зміщення
function axialToPixelRaw(q, r)
    -- Формули для pointy-top гексагонів
    local x = HEX_WIDTH * (q + r / 2)
    local y = HEX_HEIGHT * (3/4 * r)
    return x, y
end

-- Перетворення з координат осі до пікселів (pointy-top)
function axialToPixel(q, r)
    local x, y = axialToPixelRaw(q, r)
    return x + OFFSET_X, y + OFFSET_Y
end

-- Перетворення з пікселів до аксіальних координат (pointy-top)
function pixelToAxial(x, y)
    x = x - OFFSET_X
    y = y - OFFSET_Y

    local q = (x / HEX_WIDTH) - (y / HEX_HEIGHT) / 2
    local r = (4/3 * y) / HEX_HEIGHT

    return hexRound(q, r)
end

function hexRound(q, r)
    local x = q
    local z = r
    local y = -x - z

    local rx = math.floor(x + 0.5)
    local ry = math.floor(y + 0.5)
    local rz = math.floor(z + 0.5)

    local dx = math.abs(rx - x)
    local dy = math.abs(ry - y)
    local dz = math.abs(rz - z)

    if dx > dy and dx > dz then
        rx = -ry - rz
    elseif dy > dz then
        ry = -rx - rz
    else
        rz = -rx - ry
    end

    return rx, rz
end

function board.checkGameOver()
    local count1, count2 = 0, 0
    for _, piece in ipairs(board.pieces) do
        if piece.player == 1 then count1 = count1 + 1
        elseif piece.player == 2 then count2 = count2 + 1 end
    end

    if count1 == 0 or count2 == 0 then
        local ui = require("ui")
        ui.setWinner(count1 > 0 and 1 or 2, count1, count2)
        gameState = "gameover"
    end
end

return board