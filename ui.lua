local board = require("board")

local ui = {}

local font
local fonts = {}

local buttons = {
    menu = {
        {label = "Нова гра", action = function()
            board.load()
            gameState = "game"
        end},
        {label = "Налаштування", action = function()
            gameState = "settings"
        end},
        {label = "Вийти", action = function()
            love.event.quit()
        end}
    },
    settings = {
        {label = "Назад", action = function()
            gameState = "menu"
        end}
    }
}

local buttonWidth = 240
local buttonHeight = 50
local spacing = 20

function ui.load()
    -- Завантаження шрифтів
    fonts.medium = love.graphics.newFont("assets/fonts/Ubuntu-Regular.ttf", 20)
    fonts.large = love.graphics.newFont("assets/fonts/Ubuntu-Regular.ttf", 36)
    love.graphics.setFont(fonts.medium)

    gameState = "menu"
end

-- Малювання меню
function ui.drawMenu()
    love.graphics.clear(0.1, 0.1, 0.15)
    love.graphics.setFont(fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Климки — Меню гри", 0, 80, love.graphics.getWidth(), "center")

    drawButtons(buttons.menu, love.graphics.getHeight() / 2 - 100)
end

function ui.mousepressedMenu(x, y)
    handleButtonPress(x, y, buttons.menu, love.graphics.getHeight() / 2 - 100)
end

-- Малювання налаштувань
function ui.drawSettings()
    love.graphics.clear(0.15, 0.1, 0.1)
    love.graphics.setFont(fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Налаштування (тимчасово порожні)", 0, 100, love.graphics.getWidth(), "center")

    drawButtons(buttons.settings, love.graphics.getHeight() / 2 + 50)
end

function ui.mousepressedSettings(x, y)
    handleButtonPress(x, y, buttons.settings, love.graphics.getHeight() / 2 + 50)
end

-- Малювання UI під час гри
function ui.drawGameUI()
    love.graphics.setFont(fonts.medium)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Хід гравця: " .. tostring(_G.currentPlayer or 1), 20, 20)

    -- Кнопка "Меню"
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", 850, 20, 120, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 850, 20, 120, 40)
    love.graphics.printf("Меню", 850, 30, 120, "center")
end

function ui.mousepressedInGame(x, y)
    if x >= 850 and x <= 970 and y >= 20 and y <= 60 then
        gameState = "menu"
    end
end

-- Допоміжні функції для кнопок
function drawButtons(buttonList, startY)
    local centerX = love.graphics.getWidth() / 2 - buttonWidth / 2
    love.graphics.setFont(fonts.medium)

    for i, button in ipairs(buttonList) do
        local bx = centerX
        local by = startY + (i - 1) * (buttonHeight + spacing)

        love.graphics.setColor(0.3, 0.3, 0.5)
        love.graphics.rectangle("fill", bx, by, buttonWidth, buttonHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", bx, by, buttonWidth, buttonHeight)
        love.graphics.printf(button.label, bx, by + 15, buttonWidth, "center")
    end
end

function handleButtonPress(x, y, buttonList, startY)
    local centerX = love.graphics.getWidth() / 2 - buttonWidth / 2
    for i, button in ipairs(buttonList) do
        local bx = centerX
        local by = startY + (i - 1) * (buttonHeight + spacing)

        if x >= bx and x <= bx + buttonWidth and y >= by and y <= by + buttonHeight then
            if button.action then
                button.action()
                return
            end
        end
    end
end

return ui
