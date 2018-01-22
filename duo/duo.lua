--[[
duo.lua
easysid, Sunday, 21 January 2018 20:05 IST

Credits:
* mrpeachy for put_text()
* rainmeter skin - http://fav.me/db7o7rr
* weather icons  - http://fav.me/dbgs998

Changes:
* Sunday, 21 January 2018 19:51 IST
    - Initial commit
]]


weather_url = "https://www.accuweather.com/en/in/delhi/202396/current-weather/202396"
weather_update_time = 600

T = {
    -- drawing
    xc = 250,
    yc = 250,
    radius = 180,
    base_color = {0x3a434c, 1},
    top_fill = {0x16a1a4, 1},
    bottom_fill = {0x434d57, 1},
    hours_ring = 10, -- thickness
    minutes_ring = 6, --thickness
    hours_color = {0x757575, 1},
    minutes_color = {0xf48282, 1},
    -- texts --
    text_color = {0xf0f0f0, 1},
    font = 'raleway',
    -- temperature
    temp_x = 250,
    temp_y = 170,
    temp_fs = 50,
    -- time
    time_x = 250,
    time_y = 370,
    time_fs = 50,
    time_format = "%H:%M",
    -- icon
    icon_w = 100,
    icon_h = 100,

} -- end settings_t


-- ********** You should not need to change anything below this **********


local scriptpath = debug.getinfo(1,'S').source:match("@(.*/).*.lua") or './'
package.path = string.format("%s;%s?.lua", package.path, scriptpath)

require 'cairo'
require 'imlib2'
require 'helpers'

local first_run = 1


function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display,
        conky_window.drawable, conky_window.visual,
            conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    local updates = tonumber(conky_parse('${updates}'))
    local counter = updates % weather_update_time
    -- drawing code here
    if counter == 0 or first_run then
        first_run = nil
        conditions = get_accuweather(weather_url)
    end
    -- basic setup
    local temp     = conditions.temp.."°"
    local icon     = conditions.icon
    local iconfile = string.format("%sicons/%s.png", scriptpath, icon)
    local r        = T.radius - T.hours_ring
    local h_r      = r + T.hours_ring/2
    local m_r      = r - T.minutes_ring/2
    local time     = os.date(T.time_format)
    -- draw the widgets
    draw_circle({x=T.xc, y=T.yc, r=T.radius, fill_color=T.base_color})
    draw_circle({x=T.xc, y=T.yc, r=r, start=-math.pi, ends=0,
                    fill_color=T.top_fill})
    draw_circle({x=T.xc, y=T.yc, r=r, start=0, ends=math.pi,
                    fill_color=T.bottom_fill})
    draw_clock({arg='%H', max=24, x=T.xc, y=T.yc, r=h_r,
                    border_width=T.hours_ring, border_color=T.hours_color})
    draw_clock({arg='%M', max=60, x=T.xc, y=T.yc, r=m_r,
                    border_width=T.minutes_ring, border_color=T.minutes_color})
    put_text({x=T.time_x, y=T.time_y, f=T.font, fs=T.time_fs, txt=time,
                color=T.text_color, hj='c'})
    put_text({x=T.temp_x, y=T.temp_y, f=T.font, fs=T.temp_fs, txt=temp,
                color=T.text_color, hj='c'})
    put_image({x=T.xc, y=T.yc, file=iconfile, w=T.icon_w, h=T.icon_h, hj='c', vj='m'})
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end -- function main

function draw_clock(t)
    local value = tonumber(os.date(t.arg))
    local theta = scale(value, 0, t.max, 0, 2*math.pi) - math.pi/2
    draw_circle({x=t.x, y=t.y, r=t.r, start=-math.pi/2, ends=theta,
                border_width=t.border_width, border_color=t.border_color})
end --function draw_clock

function show_text(t)
    -- just a wrapper around put_text
    local value = nil
    if t.arg then value = os.date(t.arg) else value = t.label end
    put_text({x=t.x, y=t.y, f=t.font, fs=t.fs, c=t.color,
                hj=t.align, txt=string.upper(value)})
end -- function show_text

function deadbeef_nowplaying()
    -- a better approach is to use a dbus loop that writes to /tmp file
    local command = "deadbeef --nowplaying-tf '%artist%^%title%' 2> /dev/null"
    local f = io.popen(command)
    local data = f:read("*a")
    f:close()
    local t = {}
    t.artist, t.title = data:match("([^^]+)^([^^]+)")
    return t
end -- function deadbeef_nowplaying
