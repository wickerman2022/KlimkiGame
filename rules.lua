local Rules = {}

local directions = {
    {q = 1, r = 0},   -- E
    {q = 1, r = -1},  -- NE
    {q = 0, r = -1},  -- NW
    {q = -1, r = 0},  -- W
    {q = -1, r = 1},  -- SW
    {q = 0, r = 1},   -- SE
}

-- Функція для перевірки, чи знаходиться координата в межах п'ятикутного поля з 5 комірками на грань
local function isValidPosition(q, r)
    -- Для п'ятикутного поля з радіусом 4 (5 комірок на грань)
    local radius = 4
    
    -- Перевірка меж шестикутника
    if math.abs(q) > radius or math.abs(r) > radius or math.abs(q + r) > radius then
        return false
    end
    
    return true
end

local function getPieceAt(pieces, q, r)
    for _, piece in ipairs(pieces) do
        if piece.q == q and piece.r == r then
            return piece
        end
    end
    return nil
end

function Rules.getValidMoves(piece, pieces)
    local moves = {}

    -- ✳️ Король — рух і бій на довгу дистанцію
    if piece.kind == "king" then
        for _, dir in ipairs(directions) do
            local q, r = piece.q + dir.q, piece.r + dir.r

            -- Ходьба до першої зайнятої (з перевіркою меж)
            while isValidPosition(q, r) and not getPieceAt(pieces, q, r) do
                table.insert(moves, {q = q, r = r})
                q = q + dir.q
                r = r + dir.r
            end

            -- Якщо є ворожа фішка — перевіряємо, чи можна стрибнути далі
            if isValidPosition(q, r) then
                local mid = getPieceAt(pieces, q, r)
                if mid and mid.player ~= piece.player then
                    local jumpQ, jumpR = q + dir.q, r + dir.r
                    if isValidPosition(jumpQ, jumpR) and not getPieceAt(pieces, jumpQ, jumpR) then
                        table.insert(moves, {q = jumpQ, r = jumpR, capture = {q = q, r = r}})
                    end
                end
            end
        end

        return moves
    end

    -- ✳️ Звичайна фішка — рух тільки вперед
    local forwardDirs = {}
    if piece.player == 1 then
        forwardDirs = { {q = -1, r = 1}, {q = 0, r = 1} } -- SE і SW
    else
        forwardDirs = { {q = 1, r = -1}, {q = 0, r = -1} } -- NE і NW
    end

    -- Ходи вперед (з перевіркою меж)
    for _, dir in ipairs(forwardDirs) do
        local q = piece.q + dir.q
        local r = piece.r + dir.r
        if isValidPosition(q, r) and not getPieceAt(pieces, q, r) then
            table.insert(moves, {q = q, r = r})
        end
    end

    -- Захоплення — в усіх напрямках (з перевіркою меж)
    for _, dir in ipairs(directions) do
        local midQ = piece.q + dir.q
        local midR = piece.r + dir.r
        local jumpQ = midQ + dir.q
        local jumpR = midR + dir.r

        -- Перевіряємо межі для всіх позицій
        if isValidPosition(midQ, midR) and isValidPosition(jumpQ, jumpR) then
            local target = getPieceAt(pieces, midQ, midR)
            if target and target.player ~= piece.player and not getPieceAt(pieces, jumpQ, jumpR) then
                table.insert(moves, {q = jumpQ, r = jumpR, capture = {q = midQ, r = midR}})
            end
        end
    end

    return moves
end

function Rules.hasCapture(piece, pieces)
    local moves = Rules.getValidMoves(piece, pieces)
    for _, move in ipairs(moves) do
        if move.capture then return true end
    end
    return false
end

function Rules.mustCapture(player, pieces)
    for _, piece in ipairs(pieces) do
        if piece.player == player and Rules.hasCapture(piece, pieces) then
            return true
        end
    end
    return false
end

function Rules.removePieceAt(pieces, q, r)
    for i = #pieces, 1, -1 do
        if pieces[i].q == q and pieces[i].r == r then
            table.remove(pieces, i)
            return
        end
    end
end

return Rules