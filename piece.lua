local Piece = {}
Piece.__index = Piece

function Piece.new(player, kind, q, r)
    local self = setmetatable({}, Piece)
    self.player = player          -- 1 або 2
    self.kind = kind or "normal" -- "normal" або "king"
    self.q = q
    self.r = r
    return self
end

function Piece:draw(axialToPixel)
    local x, y = axialToPixel(self.q, self.r)
    local size = 16

    local triangle = calculateTriangle(x, y, size)

    -- Вибір кольору
    local color
    if self.player == 1 then
        color = {0.2, 0.6, 1.0} -- синій
    else
        color = {1.0, 0.3, 0.3} -- червоний
    end

    if self.kind == "king" then
        -- Далекобійна (лише контур)
        love.graphics.setColor(color)
        love.graphics.setLineWidth(2)
        love.graphics.polygon("line", triangle)
    else
        -- Звичайна фішка
        love.graphics.setColor(color)
        love.graphics.polygon("fill", triangle)

        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.polygon("line", triangle)
    end
end

-- Повертає вершини рівностороннього трикутника з вершиною вгору
function calculateTriangle(cx, cy, radius)
    local h = radius * math.sqrt(3) / 2

    local x1 = cx
    local y1 = cy - h * 2/3

    local x2 = cx - radius / 2
    local y2 = cy + h / 3

    local x3 = cx + radius / 2
    local y3 = cy + h / 3

    return {x1, y1, x2, y2, x3, y3}
end

return Piece
