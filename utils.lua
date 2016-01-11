local M = {}

function M.Animations()
    local anims = {}

    local function add(anim)
        anims[#anims+1] = anim
    end

    local function draw(t)
        for idx = 1, #anims do
            gl.pushMatrix()
            anims[idx](t)
            gl.popMatrix()
        end
    end

    return {
        add = add;
        draw = draw;
    }
end

function M.wrap(str, limit, indent, indent1)
    limit = limit or 72
    local here = 1
    local wrapped = str:gsub("(%s+)()(%S+)()", function(sp, st, word, fi)
        if fi-here > limit then
            here = st
            return "\n"..word
        end
    end)
    local splitted = {}
    for token in string.gmatch(wrapped, "[^\n]+") do
        splitted[#splitted + 1] = token
    end
    return splitted
end

function M.cycled(items, offset)
    offset = offset % #items + 1
    return items[offset], offset
end

function M.make_smooth(timeline)
    assert(#timeline >= 1)

    local function find_span(t)
        local lo, hi = 1, #timeline
        while lo <= hi do
            local mid = math.floor((lo+hi)/2)
            if timeline[mid].t > t then
                hi = mid - 1
            else
                lo = mid + 1
            end
        end
        return math.max(1, lo-1)
    end

    local function get_value(t)
        local t1 = find_span(t)
        local t0 = math.max(1, t1-1)
        local t2 = math.min(#timeline, t1+1)
        local t3 = math.min(#timeline, t1+2)

        local p0 = timeline[t0]
        local p1 = timeline[t1]
        local p2 = timeline[t2]
        local p3 = timeline[t3]

        local v0 = p0.val
        local v1 = p1.val
        local v2 = p2.val
        local v3 = p3.val

        local progress = 0.0
        if p1.t ~= p2.t then
            progress = math.min(1, math.max(0, 1.0 / (p2.t - p1.t) * (t - p1.t)))
        end

        if p1.ease == "linear" then 
            return (v1 * (1-progress) + (v2 * progress)) 
        elseif p1.ease == "step" then
            return v1
        elseif p1.ease == "inout" then
            return -(v2-v1) * progress*(progress-2) + v1
        else
            local d1 = p2.t - p1.t
            local d0 = p1.t - p0.t

            local bias = 0.5
            local tension = 0.8
            local mu = progress
            local mu2 = mu * mu
            local mu3 = mu2 * mu
            local m0 = (v1-v0)*(1+bias)*(1-tension)/2 + (v2-v1)*(1-bias)*(1-tension)/2
            local m1 = (v2-v1)*(1+bias)*(1-tension)/2 + (v3-v2)*(1-bias)*(1-tension)/2

            m0 = m0 * (2*d1)/(d0+d1)
            m1 = m1 * (2*d0)/(d0+d1)
            local a0 =  2*mu3 - 3*mu2 + 1
            local a1 =    mu3 - 2*mu2 + mu
            local a2 =    mu3 -   mu2
            local a3 = -2*mu3 + 3*mu2
            return a0*v1+a1*m0+a2*m1+a3*v2
        end
    end

    return get_value
end

function M.easeInOut(t, b, c)
    c = c - b
    return -c * math.cos(t * (math.pi/2)) + c + b;
end

return M
