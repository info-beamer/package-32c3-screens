local utils = require "utils"

local M = {}

function M.can_schedule()
    return true
end

-- The prepare function is called with the options given in the
-- playlist json file. This function is called once each time
-- the module is about to be scheduled. 
-- The function should return a duration (in seconds) as well
-- as a value that is later available in the run function.
function M.prepare(options)
    return 8, options
end

-- This function is running in a coroutine. It gets started
-- a few seconds before the module should be visible.
-- duration and options are the values returned by prepare.
-- fn is a table containing useful functions that can be
-- used to control the coroutine.
function M.run(duration, options, fn)
    local pos = {
        x = utils.make_smooth{
            {t = 0,    val = WIDTH/2-50},
            {t = 7,    val = WIDTH/2-50},
            {t = 8,    val = -500},
        };
        y = utils.make_smooth{
            {t = 0,    val = HEIGHT/2},
            {t = 2,    val = HEIGHT/2},
        };
    }

    local rot = {
        x = utils.make_smooth{
            {t = 0,    val = -30},
            {t = 4,    val = 0},
            {t = 8,    val = 30},
        };
        z = utils.make_smooth{
            {t = 0,    val = -2},
            {t = 4,    val = 0},
            {t = 8,    val = 2},
        };
    }

    local alpha = utils.make_smooth{
        {t = 0,  val = 0},
        {t = 0.8, val = 1},
    }

    local scale = utils.make_smooth{
        {t = 0,  val = 40.1},
        {t = 1,  val = 1.5},
        {t = 1,  val = 1.4},
        {t = 7,  val = 1.8},
        {t = 8,  val = 0},
    }

    -- local text = "32c3"
    -- local size = 200
    -- local w = res.font:width(text, size)
    local logo = resource.load_video{
        file = "loop-big.mp4",
        paused = true,
    }

    fn.wait_t(0)
    logo:start()
    Sidebar.hide(duration-1)

    for now in fn.upto_t(duration) do
        local w, h = logo:size()
        gl.pushMatrix()
            gl.translate(pos.x(now), pos.y(now))
            gl.rotate(rot.z(now), 0, 0, 1)
            -- gl.rotate(rot.x(now), 1, 0, 0)
            gl.scale(scale(now), scale(now))
            --res.font:write(-w/2, -size/2, text, size, 1,1,1,1)
            logo:draw(-w/2, -h/2, w/2, h/2, alpha(now))
        gl.popMatrix()
    end
    logo:dispose()
    return true
end

return M
