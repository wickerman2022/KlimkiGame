local board = require("board")
local ui = require("ui")

function love.load()
    ui.load()
end

function love.update(dt)
end

function love.draw()
    if gameState == "menu" then
        ui.drawMenu()
    elseif gameState == "settings" then
        ui.drawSettings()
    elseif gameState == "game" then
        board.draw()
        ui.drawGameUI()
    end
end

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        ui.mousepressedMenu(x, y)
    elseif gameState == "settings" then
        ui.mousepressedSettings(x, y)
    elseif gameState == "game" then
        board.mousepressed(x, y, button)
    end
end
