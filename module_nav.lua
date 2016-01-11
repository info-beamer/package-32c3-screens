local utils = require "utils"
local anims = require "anims"

local M = {}

local layers = util.auto_loader({}, function(fname)
    return fname:sub(1,4) == "nav-"
end)

function M.can_schedule()
    return true
end

function M.prepare(options)
    return 12, options
end

local transparent = resource.create_shader[[
    uniform sampler2D Texture;
    varying vec2 TexCoord;
    uniform vec4 Color;

    void main() {
        vec4 col = texture2D(Texture, TexCoord).rgba;
        if (col.r + col.g + col.b < 0.16) {
            gl_FragColor = vec4(1.0, 1.0, 1.0, 0.0);
        } else {
            gl_FragColor = col * Color;
        }
    }
]]

-- This function is running in a coroutine. It gets started
-- a few seconds before the module should be visible.
-- duration and options are the values returned by prepare.
-- fn is a table containing useful functions that can be
-- used to control the coroutine.
function M.run(duration, options, fn)
    local S = 0
    local E = duration-1.5

    local a = utils.Animations()

    a.add(anims.moving_font(S, E+1.5, 400-4, 100-4, "Lost? Try c3nav.de", 150, 0,0,0,0.5))
    a.add(anims.moving_font(S, E+1.5, 400+4, 100-4, "Lost? Try c3nav.de", 150, 0,0,0,0.5))
    a.add(anims.moving_font(S, E+1.5, 400-4, 100+4, "Lost? Try c3nav.de", 150, 0,0,0,0.5))
    a.add(anims.moving_font(S, E+1.5, 400+4, 100+4, "Lost? Try c3nav.de", 150, 0,0,0,0.5))
    a.add(anims.moving_font(S, E+1.5, 400,   100, "Lost? Try c3nav.de", 150, 1,1,1,1))

    local layer =  utils.make_smooth{
        {t = S,    val = -1000},
        {t = S+1,  val = 0, ease='step'},
        {t = E-1,  val =  0},
        {t = E,    val = 3000},
    };

    fn.wait_t(0)
    Sidebar.hide(duration-1)

    for now in fn.upto_t(duration) do
        -- a.draw(now)
        transparent:use()
        gl.perspective(70, math.sin(sys.now()/2)*600, -500, math.cos(sys.now()/2)*600,
                           0, -100, 0)
        gl.rotate(90, -1, 0, 0)
        for l = 0, 4 do
            gl.pushMatrix()
            gl.translate(0, 0, -30*l + layer(now-l*0.4))
            util.draw_correct(layers['nav-level' .. l], -1120/2, -720/2, 1120/2, 720/2, 0.8)
            gl.popMatrix()
        end
        transparent.deactivate()
        gl.ortho()
        a.draw(now)
    end
    return true
end

return M

