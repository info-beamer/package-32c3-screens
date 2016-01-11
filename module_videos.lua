local utils = require "utils"
local raw = sys.get_ext "raw_video"

local M = {}

local video_idx = 0
local black = resource.create_colored_texture(0,0,0,1)

function M.can_schedule(options)
    return #options.videos > 0
end

function M.prepare(options)
    local video 
    video, video_idx = utils.cycled(options.videos, video_idx)
    return video.duration, {
        file = resource.open_file(video.file),
        raw = video.raw,
        text = video.text,
    }
end

function M.run(duration, args, fn)
    local text_size = 70

    local text_w = res.font:width(args.text, text_size)

    local text_x = utils.make_smooth{
        {t = 0,          val = WIDTH-200},
        {t = 1,          val = WIDTH - text_w - 200},
        {t = duration-1, val = WIDTH - text_w - 200},
        {t = duration,   val = WIDTH - text_w},
    }
    local text_y = utils.make_smooth{
        {t = 0,          val = HEIGHT},
        {t = 1,          val = 90},
        {t = duration-1, val = 90},
        {t = duration,   val = -500},
    }
    local text_r = utils.make_smooth{
        {t = 0, val = 90},
        {t = 1, val = 10},
        {t = 2, val = 10},
        {t = duration-1, val =  5},
        {t = duration, val = 180},
    }

    if args.raw then
        local vid = raw.load_video{
            file = args.file:copy(),
            paused = true,
        }

        for now in fn.wait_next_frame do
            local state, err = vid:state()
            if state == "loaded" then
                break
            elseif state == "error" then
                error("preloading failed: " .. err)
            end
        end

        local _, w, h = vid:state()

        local x = utils.make_smooth{
            {t = 0,            val = WIDTH},
            {t = 1,            val = (WIDTH-w)/2, ease='step'},
            {t = duration-1,   val = (WIDTH-w)/2},
        }
        local y = utils.make_smooth{
            {t = 0,           val = 300},
            {t = 1,           val = (HEIGHT-h)/2, ease='step'},
            {t = duration-1,  val = (HEIGHT-h)/2},
            {t = duration,    val = HEIGHT+100},
        }

        fn.wait_t(0)

        Sidebar.hide(duration-1)
        -- Fadeout.fade(duration-1)

        for now in fn.upto_t(duration) do
            if now > 1 then
                vid:start()
            end
            local x, y = x(now), y(now)
            vid:target(x, y, x+w, y+h):layer(-1)

            gl.pushMatrix()
                gl.translate(text_x(now), text_y(now))
                gl.rotate(text_r(now), 0, 1, 0)
                black:draw(-10, -10, text_w+10, text_size+10, 0.6)
                res.font:write(0, 0, args.text, text_size, 1,1,1,1)
            gl.popMatrix()
        end

        vid:dispose()
        return true
    else
        local x = utils.make_smooth{
            {t = 0,   val = 600},
            {t = 1,   val = 50},
            {t = duration-1,   val = 50},
            {t = duration,   val = -1000},
        }
        local y = utils.make_smooth{
            {t = 0,  val = 300},
            {t = 1,  val = 0},
            {t = duration-1,  val = 20},
            {t = duration,  val = 900},
        }
        local rotate = utils.make_smooth{
            {t = 0, val = 90},
            {t = 1, val = -10},
            {t = 2, val = -10},
            {t = duration-1, val =  -5},
            {t = duration, val = -180},
        }
        local scale = utils.make_smooth{
            {t = 0,   val = 0},
            {t = 1,   val = 0.94},
            {t = duration-1,   val = 0.90},
            {t = duration,   val = 0},
        }

        local vid = resource.load_video{
            file = args.file:copy(),
            paused = true,
        }

        fn.wait_t(0)

        Sidebar.hide(duration-1)
        -- Fadeout.fade(duration-1)

        for now in fn.upto_t(duration) do
            if now > 1 then
                vid:start()
            end

            gl.pushMatrix()
                gl.rotate(rotate(now), 0, 1, 0)
                gl.translate(x(now), y(now))
                local scale = scale(now)
                util.draw_correct(vid, 0, 0, WIDTH*scale, HEIGHT*scale)
            gl.popMatrix()

            gl.pushMatrix()
                gl.translate(text_x(now), text_y(now))
                gl.rotate(text_r(now), 0, 1, 0)
                black:draw(-10, -10, text_w+10, text_size+10, 0.5)
                res.font:write(0, 0, args.text, text_size, 1,1,1,1)
            gl.popMatrix()
        end

        vid:dispose()
        return true
    end
end

return M
