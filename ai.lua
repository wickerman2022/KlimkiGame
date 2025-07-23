local Rules = require("rules")

local ai = {}

local function evaluate(pieces)
    local score = 0
    for _, piece in ipairs(pieces) do
        local val = (piece.kind == "king") and 3 or 1
        score = score + (piece.player == 2 and val or -val)
    end
    return score
end

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function findPiece(pieces, q, r, player)
    for _, piece in ipairs(pieces) do
        if piece.q == q and piece.r == r and piece.player == player then
            return piece
        end
    end
end

-- Мінімакс без алфа-бета (глибина 2)
local function minimax(pieces, depth, maximizingPlayer)
    if depth == 0 then
        return evaluate(pieces), nil
    end

    local bestScore = maximizingPlayer and -math.huge or math.huge
    local bestMove = nil

    for _, piece in ipairs(pieces) do
        if piece.player == (maximizingPlayer and 2 or 1) then
            local moves = Rules.getValidMoves(piece, pieces)
            for _, move in ipairs(moves) do
                local newPieces = deepCopy(pieces)
                local simPiece = findPiece(newPieces, piece.q, piece.r, piece.player)

                simPiece.q = move.q
                simPiece.r = move.r

                if move.capture then
                    for i = #newPieces, 1, -1 do
                        if newPieces[i].q == move.capture.q and newPieces[i].r == move.capture.r then
                            table.remove(newPieces, i)
                            break
                        end
                    end
                end

                if simPiece.player == 1 and simPiece.r == 4 then
                    simPiece.kind = "king"
                elseif simPiece.player == 2 and simPiece.r == -4 then
                    simPiece.kind = "king"
                end

                local score = minimax(newPieces, depth - 1, not maximizingPlayer)

                if maximizingPlayer then
                    if score > bestScore then
                        bestScore = score
                        bestMove = {piece = piece, move = move}
                    end
                else
                    if score < bestScore then
                        bestScore = score
                        bestMove = {piece = piece, move = move}
                    end
                end
            end
        end
    end

    return bestScore, bestMove
end

-- 🔁 Ланцюгові стрибки (рекурсивно)
local function applyMoveWithChain(piece, move, board)
    piece.q = move.q
    piece.r = move.r

    if move.capture then
        Rules.removePieceAt(board.pieces, move.capture.q, move.capture.r)
    end

    -- Перетворення в короля
    if piece.player == 2 and piece.r == -4 then
        piece.kind = "king"
    end

    -- Перевірка на ще один стрибок
    local furtherMoves = Rules.getValidMoves(piece, board.pieces)
    for _, m in ipairs(furtherMoves) do
        if m.capture then
            -- Рекурсивно продовжуємо ланцюг
            applyMoveWithChain(piece, m, board)
            break
        end
    end
end

-- 🔹 Основна функція AI
function ai.makeMove(board)
    local _, best = minimax(board.pieces, 2, true)

    if best and best.piece and best.move then
        -- Шукаємо реальну фішку на полі
        local realPiece = board.getPieceAt(best.piece.q, best.piece.r)
        if realPiece then
            applyMoveWithChain(realPiece, best.move, board)
            board.currentPlayer = 1
            board.selected = nil
            board.possibleMoves = {}
        end
    end
end

return ai
