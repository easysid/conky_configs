--[[
lua script for stamps conky
Thu 20 Jun 2013 12:38:06 IST
written by easysid
Modified:
Wed 26 June 2013 11:34:15 IST
 * Converted the conky to lua only. Each stamp is now independent.
 * Added function get_stampimage
]]--

require 'cairo'
require 'imlib2'

-- Change this path to where the image files are
imagedir=''

function conky_main()

local settings_table = {
    -- stamp1
    {
        x=0,    -- top left corners of image
        y=10,
        w=200,  -- width and height
        h=100,
        file='stamp2', --[[ the stamp image file. If you do not provide this arg,
                the script will use one according to the dimensions.
                [see README and get_stampimage() ]]--
        fill_color = {0x990012, 0.9}, --fill color for stamp

        border=5, -- fill gap from stamp image. optional. default 5
        font = 'segoe ui semibold', --[[ default font for text. These can be    overridden by passing the corresponding arguments in labels.
        The default font is monospace. You can change it in line 286  ]]--

        fs=14, --default font size
        text_color = {0xffffff, 0.9}, --default text color

        --[[
        These are the text labels to be put on the stamp.
        The format is same as that of out() function.[see below for out()]
        The coords here are according to x and y above being (0,0)
        This ensures that stamps can be adjusted individually.
        *note how the conky variables are passed.
        *Any font, size and color args will override the defaults above.
        e.g The Arch logo using dark gray and openlogos font ]]--

        lables = {
            {x=70, y=80, fs=70, font='openlogos', color={0x121212, 0.5}, centred=true, text="B"},
            {x=10, y=25, text="${time %B %d}"},
            {x=120, y=25, text="${time %A}"},
            {x=75, y=55, fs=35, centred=true, text="${time %H:%M}"},
            {x=10, y=85, text="${kernel}"},
            {x=130, y=85, text="${uptime_short}"}
        }
    },

    -- stamp2 (cpu)
    {
        x=0,
        y=115,
        w=100,
        h=90,
        file='stamp3',
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x254117, 0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=35, y=50, fs=20, text="cpu"},
            {x=65, y=25, text="${cpu cpu0}%"},
            {x=10, y=75, text="${cpu cpu1}%"},
            {x=65, y=75, text="${cpu cpu3}%"},
        }
    },

    -- stamp3 (ram)
    {
        x=100,
        y=115,
        w=100,
        h=90,
        file='stamp3',
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x254117, 0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=35, y=50, fs=20, text="ram"},
            {x=60, y=25, text="${memperc}%"},
            {x=15, y=75, text="using ${mem}"}
        }
    },

    -- stamp4 (temp1)
    {
        x=0,
        y=210,
        w=66,
        h=66,
        file='stamp3',
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x8b2500,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=18, y=45, fs=20, text="cpu"},
            {x=35, y=22, text="${platform coretemp.0 temp 2}°"},
        }
    },

    -- stamp5 (temp2)
    {
        x=66,
        y=210,
        w=66,
        h=66,
        file='stamp3',
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x8b2500,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=18, y=45, fs=20, text="ati"},
            {x=35, y=22, text="${hwmon 2 temp 1}°"},
        }
    },
    -- stamp6 (temp3)
    {
        x=132,
        y=210,
        w=66,
        h=66,
        file='stamp3',
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x8b2500,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=18, y=45, fs=20, text="hdd"},
            {x=35, y=22, text="${execi 20 hddtemp /dev/sda -n }°"},
        }
    },

    -- stamp7 (fs1)
    {
        x=0,
        y=280,
        w=66,
        h=115,
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x3B3131,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=30, y=50, fs=16, text="/"},
            {x=30, y=25, text="${fs_used_perc /}%"},
            {x=15, y=77, text="${fs_used /}"},
            {x=15, y=98, text="${fs_size /}"},
            {x=13, y=83, text="_______"},

        }
    },
    -- stamp8 (fs2)
    {
        x=66,
        y=280,
        w=66,
        h=115,
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x3B3131,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=13, y=50, fs=16, text="home"},
            {x=30, y=25, text="${fs_used_perc /home}%"},
            {x=15, y=77, text="${fs_used /home}"},
            {x=15, y=98, text="${fs_size /home}"},
            {x=13, y=83, text="_______"},

        }
    },
    -- stamp9 (fs3)
    {
        x=132,
        y=280,
        w=66,
        h=115,
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x3B3131,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=13, y=50, fs=16, text="DATA"},
            {x=30, y=25, text="${fs_used_perc /media/DATA}%"},
            {x=15, y=77, text="${fs_used /media/DATA}"},
            {x=15, y=98, text="${fs_size /}"},
            {x=13, y=83, text="_______"},

        }
    },

    -- stamp10 (proc1)
    {
        x=0,
        y=400,
        w=100,
        h=70,
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x990012,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=10, y=40, text="${top_mem name 1}"},
            {x=50, y=23, text="${top_mem cpu 1}%"},
            {x=50, y=58, text="${top_mem mem_res 1}"}
        }
    },
    -- stamp11 (proc2)
    {
        x=100,
        y=400,
        w=100,
        h=70,
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0xee4000,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=10, y=40, text="${top_mem name 2}"},
            {x=50, y=23, text="${top_mem cpu 2}%"},
            {x=50, y=58, text="${top_mem mem_res 2}"}
        }
    },
    -- stamp12 (proc3)
    {
        x=0,
        y=470,
        w=100,
        h=70,
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x8b2500,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=10, y=40, text="${top_mem name 3}"},
            {x=50, y=23, text="${top_mem cpu 3}%"},
            {x=50, y=58, text="${top_mem mem_res 3}"}
        }
    },
    -- stamp13 (proc4)
    {
        x=100,
        y=470,
        w=100,
        h=70,
        font = 'segoe ui semibold',
        fs=14,
        fill_color = {0x806517,0.9},
        text_color = {0xffffff, 0.9},
        lables = {
            {x=10, y=40, text="${top_mem name 4}"},
            {x=50, y=23, text="${top_mem cpu 4}%"},
            {x=50, y=58, text="${top_mem mem_res 4}"}
        }
    },
} -- end settings_table

    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display,
         conky_window.drawable, conky_window.visual,
          conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    for i in ipairs(settings_table) do
        draw_stamp(settings_table[i])
    end
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end --end main()


function draw_stamp(t)

    -- set defaults
    local b = t.border or 5
    default_font = t.font or 'monospace'
    default_fs = t.fs or 16
    default_text_color = t.text_color or {0xffffff, 0.8}
    if not (t.w and t.h) then
       print('image dimensions not set !!')
       return
    end
    t.file = t.file or get_stampfile(t.w, t.h)
    local show = imlib_load_image(imagedir..tostring(t.file))
    if show == nil then return end
    imlib_context_set_image(show)
    imlib_context_set_image(show)
    local scaled=imlib_create_cropped_scaled_image(0, 0,
             imlib_image_get_width(), imlib_image_get_height(),
             t.w, t.h)
    imlib_free_image()
    imlib_context_set_image(scaled)
    imlib_render_image_on_drawable(t.x, t.y)
    imlib_free_image()
    show=nil
    --fill with color
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.fill_color))
    cairo_set_line_width(cr, 2)
    cairo_rectangle(cr, t.x+b, t.y+b, t.w-2*b, t.h-2*b)
    cairo_fill(cr)

    -- Draw the text
    for i in ipairs(t.lables) do
        t.lables[i].x = t.lables[i].x + t.x
        t.lables[i].y = t.lables[i].y + t.y
        t.lables[i].text = conky_parse(t.lables[i].text)
        out(t.lables[i])
    end --for
end -- draw_stamps()


function get_stampfile(w, h)
   --return the file based on dimensions
   local r = w/h
   if r >= 1.3 then return 'stamp2'
   elseif r < 0.75 then return 'stamp1'
   else return 'stamp3'
   end --if
end -- end get_stampfile()


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
    centred - boolean. default false. Centre the text at x,y.
    ]]--

    -- checks
    t.font = t.font or default_font
    t.fs = t.fs or default_fs
    t.color = t.color or default_text_color
    t.text = t.text or 'text'
    t.centred = t.centred or false
    t.bold = t.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    t.italic = t.italic and CAIRO_FONT_SLANT_ITALIC or CAIRO_FONT_SLANT_NORMAL

    --centred text
    if t.centred then
        local ext = cairo_text_extents_t:create()
        cairo_text_extents(cr,t.text,ext)
        t.x = t.x-(ext.width/2 + ext.x_bearing)
        t.y = t.y-(ext.height/2 + ext.y_bearing)
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
