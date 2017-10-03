--[[
colorfill.lua
lua script for colors conky
based on LIM!T rainmeter skin (http://injust29.deviantart.com/art/LIM-T-1-2-344112531)
easysid
Monday, 23 January 2017 13:44 IST
Update:
    Tuesday, 24 January 2017
        * Allow conky vars as labels
        * catch nil value errors
]]--

require 'cairo'

-- common
local base = {0x404040, 1} -- {base fill color, alpha}
local font_face = 'champagne & limousines'

local settings_t = {
    {
        label = "CPU",      -- simple label
        arg = "cpu cpu0",
        max = 100,
        x = 20,
        y = 240,
        color = {0x912d2d, 1},
        font = font_face,
        size = 60,
    },
    {
        label = "RAM",
        arg = "memperc",
        max = 100,
        x = 165,
        y = 240,
        color = {0xa9309f, 1},
        font = font_face,
        size = 60,
    },
    {
        label = "BAT",
        arg = "battery_percent BAT0",
        max = 100,
        x = 310,
        y = 240,
        color = {0x1d7235, 1},
        font = font_face,
        size = 60,
    },
    {
        label = nil,        -- no label, use the arg value
        arg = "time %H",
        max = 24,
        x = 10,
        y = 160,
        color = {0xd07036, 1},
        font = font_face,
        size = 160
    },
    {
        label = nil,
        arg = "time %M",
        max = 60,
        x = 240,
        y = 160,
        color = {0x3f75d7, 1},
        font = font_face,
        size = 160,
    },
    {
        label = nil,
        arg = "time %d",
        max = 30,
        x = 420,
        y = 90,
        color = {0x0fb575, 1},
        font = font_face,
        size = 60
    },
    {
        label = "time %B",      -- conky var as a label
        parse_label = true,     -- we need to parse the label value
        arg = "time %m",
        max = 12,
        x = 500,
        y = 90,
        color = {0xd07036, 1},
        font = font_face,
        size = 60
    },
    {
        label = "time %A",
        parse_label = true,
        arg = "time %u",
        max = 7,
        x = 420,
        y = 160,
        color = {0xa9309f, 1},
        font = font_face,
        size = 80
    },
}

-- ###### should not need to edit below this line ###### --

function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display,
    conky_window.drawable, conky_window.visual,
    conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    local updates=tonumber(conky_parse('${updates}'))
    if updates > 3 then
        for i in ipairs(settings_t) do
            drawText(settings_t[i])
        end -- for
    end
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end --end main()

function drawText(t)
    local text = conky_parse(string.format("${%s}", t.arg))
    local value = tonumber(text)
    -- catch any nil value errors
    if value == nil then
        print(string.format("{%s} returned a nil value", t.arg))
        return
    end
    -- label jugglery
    if t.label then
        text = t.label
        if t.parse_label then
            text = conky_parse(string.format("${%s}", t.label))
        end
    end
    local x = t.x or 100
    local y = t.y or 100
    local font = t.font or "sans"
    local size = t.size or 50
    local col = t.color or {0xFFFFFF, 1}
    local max = t.max or 100
    local perc = 1 - value/max
    local extents=cairo_text_extents_t:create()
    tolua.takeownership(extents)
    cairo_select_font_face(cr, font, 0, 0)
    cairo_set_font_size(cr, size)
    cairo_text_extents(cr, text, extents)
    local w = extents.width
    local h = extents.height
    local pat = cairo_pattern_create_linear(x, y-h, x, y)
    cairo_pattern_add_color_stop_rgba(pat, perc, rgba_to_r_g_b_a(base))
    cairo_pattern_add_color_stop_rgba(pat, perc, rgba_to_r_g_b_a(col))
    cairo_set_source(cr, pat)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
    cairo_stroke(cr)
end

function rgba_to_r_g_b_a(tcolor)
    local color,alpha=tcolor[1],tcolor[2]
    return ((color / 0x10000) % 0x100) / 255.,
    ((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end
