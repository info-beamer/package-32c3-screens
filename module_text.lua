local utils = require "utils"
local anims = require "anims"

local M = {}

local READING_SPEED = 10 -- characters per second

function M.can_schedule()
    return true
end

function M.prepare(options)
    return #options.text / READING_SPEED + 2, utils.wrap(options.text, 23)
end

function M.run(duration, lines, fn)
    local y = 100
    local a = utils.Animations()

    local S = 0.0
    local E = duration

    for idx = 1, #lines do
        a.add(anims.moving_font(S, E, 200, y, lines[idx], 150, 1,1,1,1)); S=S+0.1; y=y+150
    end

    fn.wait_t(0)
    Sidebar.hide(E-1)

    for now in fn.upto_t(E) do
        a.draw(now)
    end
    return true
end

return M
