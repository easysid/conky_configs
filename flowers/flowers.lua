--[[
flowers.lua for flowers conky
written by easysid
Fri 31 May 2013 17:03:39 IST
]]--

require 'cairo'


function conky_flowers_main()
    t = {
    {
        xc = 110, --placement
        yc = 220,
        size = 120, --size of petal.
        radius = 16, --radius of centre circle
        label = 'cpu',
        args = {
        --[[ 1 for each petal in clockwise manner, starting from top left petal.
         Specify the full conky variable.
         You can skip any number of them by passing any non nil value
         (e.g '  ', '.' etc.), at its place.
         ]]--
           '${cpu cpu0}%',
           '${cpu cpu1}%',
           '${cpu cpu2}%',
           '${cpu cpu3}%',
        },
        font_name = "monofur", -- for label and values
        label_font_size = 16, --label
        value_font_size = 14, --values
        bg_color = {0xd1d1d1, 0.7}, -- petals
        fg_color = {0x41a317, 0.6}, -- centre
        label_color = {0xd3d3d3, 0.8}, -- label
        value_color = {0x254117,0.9}, -- values
    },
    {
        xc = 240,
        yc = 270,
        size = 120,
        radius = 18,
        label = 'temp',
        args = {
        '${platform coretemp.0 temp 2}°',
        '${platform coretemp.0 temp 4}°',
        '${hwmon 2 temp 1}°',
        '${execi 10 hddtemp /dev/sda -n }°'
        },
        font_name = "monofur",
        label_font_size = 14.5, --label
        value_font_size = 14, --values
        bg_color = {0xd1d1d1, 0.7}, -- petals
        fg_color = {0xF01210, 0.6}, -- centre
        label_color = {0xd3d3d3, 0.8}, -- text
        value_color = {0x981234,0.8}, --values
    },

    {
        xc = 110,
        yc = 350,
        size = 120,
        radius = 16,
        label = 'mem',
        args = {
        '${memperc}%',
        '${fs_used_perc /}%',
        '${fs_used_perc /home}%',
        '${fs_used_perc /media/DATA}%',
        },
        font_name = "monofur",
        label_font_size = 16,
        value_font_size = 14,
        bg_color = {0xd1d1d1, 0.7}, -- petals
        fg_color = {0x735aff, 0.6}, -- centre
        label_color = {0xd3d3d3, 0.8}, -- text
        value_color = {0x4611af,0.9},
    },

    {
        xc = 240,
        yc = 400,
        size = 120,
        radius = 17,
        label = 'misc',
        args = {
        '${battery_short BAT0}',
        '${if_existing /proc/net/route wlan0}net${else}off${endif}',
        "${execi 30 amixer get Master | grep '%' | cut -c 22-23}%",
        '${execi 10 cat /sys/class/backlight/acpi_video0/brightness}',
        },
        font_name = "monofur",
        label_font_size = 14,
        value_font_size = 14,
        bg_color = {0xd1d1d1, 0.7}, -- petals
        fg_color = {0xb93b8f, 0.6}, -- centre
        label_color = {0xd3d3d3, 0.8}, -- text
        value_color = {0x7d1b7e,0.9},
    },
}-- end t

    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display,
        conky_window.drawable, conky_window.visual,
        conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    local updates=tonumber(conky_parse('${updates}'))
    if updates>3 then
        for i in ipairs(t) do
            flower_power(cr,t[i])
        end --for
    end --endif
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end --end main()



function flower_power(cr,t)

        for i in ipairs(t.args) do
            t.args[i] = conky_parse(t.args[i])
        end
    -- start drawing
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.bg_color))
    cairo_set_line_width (cr, 2.0)
    -- top_left leaf
    cairo_move_to (cr, t.xc, t.yc);
    cairo_curve_to (cr, t.xc, t.yc-t.size, t.xc-t.size, t.yc, t.xc, t.yc)
    -- top_right leaf
    cairo_curve_to (cr, t.xc, t.yc-t.size, t.xc+t.size, t.yc, t.xc, t.yc)
    -- bottom_right leaf
    cairo_curve_to (cr, t.xc, t.yc+t.size, t.xc+t.size, t.yc, t.xc, t.yc)
    -- bottom_left leaf
    cairo_curve_to (cr, t.xc, t.yc+t.size, t.xc-t.size, t.yc, t.xc, t.yc)

    cairo_fill(cr)

    -- Draw the centre circle
    cairo_set_operator(cr,CAIRO_OPERATOR_CLEAR) --clear the area
    cairo_arc(cr, t.xc, t.yc, t.radius, 0, 2*math.pi)
    cairo_fill(cr)
    cairo_set_operator(cr,CAIRO_OPERATOR_OVER) --draw the circle
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.fg_color))
    cairo_arc(cr, t.xc, t.yc, t.radius, 0, 2*math.pi)
    cairo_fill(cr)

    -- Place label. See the out() function for details.
    out({x=t.xc, y=t.yc, text=t.label, color=t.label_color,
     font=t.font_name, fs=t.label_font_size, centred=true})

    --Place values
    local dx = 4 -- these are scaling factors
    local dy = 4 -- change here for text adjustments
    out({x=t.xc-t.size/dx, y=t.yc-t.size/dy, text=t.args[1],
     color=t.value_color, font=t.font_name, fs=t.value_font_size,
      centred=true, bold=true})
    out({x=t.xc+t.size/dx, y=t.yc-t.size/dy, text=t.args[2],
     color=t.value_color, font=t.font_name, fs=t.value_font_size,
      centred=true, bold=true})
    out({x=t.xc+t.size/dx, y=t.yc+t.size/dy, text=t.args[3],
     color=t.value_color, font=t.font_name, fs=t.value_font_size,
      centred=true, bold=true})
    out({x=t.xc-t.size/dx, y=t.yc+t.size/dy, text=t.args[4],
     color=t.value_color, font=t.font_name, fs=t.value_font_size,
      centred=true, bold=true})

end -- end flower_power


function out(t)
    --[[ function to put the text
    arguments:
    x,y - position of the text (bottom-left) -mandatory
    text - text to display

    optional arguments:
    font - font face
    fs - font size
    color - color in {hexvalue, alpha} pair
    bold - boolean. default false. Bold text
    italic - boolean. default false
    centred - boolean. default false. Centre the text at x,y instead of starting from it.
    ]]--

    -- checks
    t.font = t.font or 'monospace'
    t.fs = t.fs or 14
    t.color = t.color or {0xffffff,1}
    t.text = t.text or 'text'
    t.centred = t.centred or false
    t.bold = t.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    t.italic = t.italic and CAIRO_FONT_SLANT_ITALIC or CAIRO_FONT_SLANT_NORMAL

    if t.centred then
        local ext = cairo_text_extents_t:create()
        cairo_text_extents(cr,t.text,ext)
        t.x = t.x - ext.width/2
        t.y = t.y + ext.height/4
    end
    --setup
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.color))
    cairo_select_font_face (cr, t.font, t.italic, t.bold)
    cairo_set_font_size (cr, t.fs)
    --print
    cairo_move_to(cr,t.x,t.y)
    cairo_show_text(cr,t.text)

end -- end out


function rgba_to_r_g_b_a(tcolor)
    local color,alpha=tcolor[1],tcolor[2]
    return ((color / 0x10000) % 0x100) / 255.,
        ((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end --end rgba
