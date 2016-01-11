local json = require "json"
local utils = require "utils"
local anims = require "anims"

local M = {}

local SPEAKER_SIZE = 50
local TITLE_SIZE = 60
local TIME_SIZE = 60

local ready = false
local talks = {}
local room_full = {}

local unwatch = util.file_watch("talks.json", function(raw)
    print "talk.json updated!"
    talks = json.decode(raw)
    ready = true
end)

local saal_unwatch = util.file_watch("room-full.json", function(raw)
    room_full = json.decode(raw)
end)


function M.unload()
    unwatch()
    saal_unwatch()
end

function M.can_schedule()
    return ready
end

function M.prepare(options)
    local now = Time.unixtime()

    print("now = ", now)

    local lineup = {}
    for idx = 1, #talks do
        local talk = talks[idx]

        -- Aktuell laufende (fuer 15 Minuten)
        if now > talk.start_unix and now < talk.end_unix then
            if talk.start_unix + 15 * 60 > now then
                lineup[#lineup+1] = talk
            end
        end

        -- Bald startende
        if talk.start_unix > now and #lineup < 8 then -- and talk.start_unix < now + 86400 then
            lineup[#lineup+1] = talk
        end
    end

    table.sort(lineup, function(t1, t2)
        return t1.start_unix < t2.start_unix or (t1.start_unix == t2.start_unix and t1.place < t2.place)
    end)

    print(#talks, "talks, ", #lineup, "lineups")

    local next_talks = {}
    local places = {}
    local redundant = false
    for idx = 1, #lineup do
        local talk = lineup[idx]
        if #next_talks <= 8 then
            redundant = redundant or places[talk.place];
            next_talks[#next_talks+1] = {
                speakers = #talk.speakers == 0 and {"?"} or talk.speakers;
                place = talk.place;
                lines = utils.wrap(talk.title .. " (" .. talk.lang .. ")", 45);
                start_str = talk.start_str;
                start_unix = talk.start_unix;
                redundant = redundant;
                started = talk.start_unix < now;
            }
            if talk.start_unix > now then
                places[talk.place] = true
            end
        end
    end

    return options.duration or 10, next_talks
end

function M.run(duration, next_talks, fn)
    local y = 50
    local x = 100
    local a = utils.Animations()

    local S = 0
    local E = duration

    if #next_talks == 0 then
        a.add(anims.moving_font(S, E, x+180, y+400, "No more talks :(", 160, 1,1,1,1)); y=y+60; S=S+0.5
    end

    local full_shown = {}

    for idx = 1, #next_talks do
        local talk = next_talks[idx]

        if y + #talk.lines*TITLE_SIZE + SPEAKER_SIZE > HEIGHT - 60 then
            break
        end

        local start_y = y

        local now = Time.unixtime()
        local time
        local show_full = false
        local til = talk.start_unix - now
        if til > 0 and til < 60 then
            time = "Now"
            local w = res.font:width(time, TIME_SIZE)
            a.add(anims.moving_font(S, E, x+180-w, y, time, TIME_SIZE, 0.94,0.57,0.14,1))
            show_full = true
        elseif til > 0 and til < 15 * 60 then
            time = string.format("In %d min", math.floor(til/60))
            local w = res.font:width(time, TIME_SIZE)
            a.add(anims.moving_font(S, E, x+180-w, y, time, TIME_SIZE, 0.94,0.57,0.14,1))
            show_full = true
        elseif talk.start_unix > now then
            time = talk.start_str
            local w = res.font:width(time, TIME_SIZE)
            a.add(anims.moving_font(S, E, x+180-w, y, time, TIME_SIZE, 1,1,1,1))
        else
            time = string.format("%d min ago", math.ceil(-til/60))
            local w = res.font:width(time, TIME_SIZE)
            a.add(anims.moving_font(S, E, x+180-w, y, time, TIME_SIZE, .5,.5,.5,1))
            show_full = true
        end

        for idx = 1, #talk.lines do
            local line = talk.lines[idx]
            a.add(anims.moving_font(S, E, x+220, y, line, TITLE_SIZE, 1,1,1,1))
            y = y + TITLE_SIZE
        end
        S = S + 0.05
        y = y + 5

        local text = talk.place .. " with "
        a.add(anims.moving_font(S, E, x+220, y, text, SPEAKER_SIZE, .5,.5,.5,1)); S=S+0.1
        local w = res.font:width(text, SPEAKER_SIZE)
        a.add(anims.moving_font_list(S, E, x+220+ w + 5, y, talk.speakers, SPEAKER_SIZE, .5,.5,.5,1))

        if show_full and room_full[talk.place] and not full_shown[talk.place] then
            full_shown[talk.place] = true
            a.add(anims.voll(S, E, x+220, start_y))
        end

        S = S + 0.05
        y = y + SPEAKER_SIZE + 25
    end

    Fadeout.fade(duration-1)

    for now in fn.upto_t(E) do
        a.draw(now)
    end
    
    fn.wait_t(E+2)

    return true
end

return M

