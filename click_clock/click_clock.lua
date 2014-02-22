--[[ Clock for conky
written by easysid
Thu 09 May 2013 19:20:16 IST
modified for Sector11
Mon 03 Jun 2013 22:26:55 IST

]]--

require 'cairo'

function conky_main()

clock_table = {
    {
        -- Draw the seconds
        arg = "time %S",
        xc = 300,
        yc = 200,
        r  = 150, -- radius
        divs = 60, --divisions or max value. default is 60.
        font_face = "monofur",
        top_font_size = 24, -- font size for display
        min_font_size = 8,  -- min font for trail
        max_font_size = 18, -- max font fot trail
        max_alpha = .6,     -- max alpha for trail
        trail = 40,         -- size of trail. Must be less than divs
        main_color = {0xFFFFFF, 1}, --color of numbers
        trail_color = {0xFFFFFF, 1} --color of trail.
    },

    {
        -- Draw the Minutes
        arg = "time %M",
        xc = 300,
        yc = 200,
        r  = 100,        -- radius
        font_face = "monofur",
        top_font_size = 26, -- font size for display
        min_font_size = 8,  -- min font for trail
        max_font_size = 16, -- max font fot trail
        max_alpha = .6,     -- max alpha for trail
        trail = 40,         -- size of trail
        main_color = {0xFFFFFF, 1}, --color of numbers
        trail_color = {0xFFFFFF, 1} --color of trail
    },

    {
        -- Draw the Hours
        arg = "time %H",
        xc = 300,
        yc = 200,
        r  = 60,
        divs = 12, -- divisions. default is 60
        font_face = "monofur",
        top_font_size = 30, -- font size for display
        min_font_size = 10,  -- min font for trail
        max_font_size = 20, -- max font fot trail
        max_alpha = .6,     -- max alpha for trail
        trail = 12,         -- size of trail
        main_color = {0xFFFFFF, 1}, --color of numbers
        trail_color = {0xFFFFFF, 1} --color of trail
    },
}
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    local updates=tonumber(conky_parse('${updates}'))
    if updates>3 then
        for i in ipairs(clock_table) do
            draw_clock(cr, clock_table[i])
        end
    end
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end-- end main function


function draw_clock(cr, t)

    local divs = t.divs or 60
    local value = tonumber(conky_parse(string.format("${%s}",t.arg)))
    local first = value - t.trail
    for i = first, value do
        local theta = i*2*math.pi/divs -math.pi/2 -- calculate the angle
        t.trail_color[2] = t.max_alpha*(i-first)/(value-first) -- map alpha value to [0, max_alpha]
        local font_size = (t.max_font_size-t.min_font_size)*(i-first)/(value-first) + t.min_font_size -- map font size similar to alpha
        if i == value then -- if we have the main value
            out({x = t.xc + t.r*math.cos(theta), y = t.yc + t.r*math.sin(theta),
         font=t.font_face, fs=t.top_font_size, text=value, color=t.main_color})
        else
            local k = i
            if k < 0 then k = divs + i end  -- adjust negatives
            out({x = t.xc + t.r*math.cos(theta), y = t.yc + t.r*math.sin(theta),
         font=t.font_face, fs=font_size, text=k, color=t.trail_color})
        end --if
    end -- end for

end -- end draw_clock

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
