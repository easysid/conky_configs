--[[ Clock for conky
written by easysid
Thu 09 May 2013 19:20:16 IST
]]--

require 'cairo'

function conky_main()

clock_table ={
    {
        -- Draw the seconds
        arg = "time %S",
        xc = 200,
        yc = 150,
        r  = 130, -- radius
        font_face = "monofur",
        top_font_size = 30, -- font size for display
        min_font_size = 6,  -- min font for trail
        max_font_size = 17, -- max font fot trail
        max_alpha = .7,     -- max alpha for trail
        trail = 40,         -- size of trail
        main_color = {0xffffff, 1}, --color of numbers
        trail_color = {0xf4f4f4, 1} --color of trail.
    },

    {
        -- Draw the Minutes
        arg = "time %M",
        xc = 200,
        yc = 150,
        r  = 85,        -- radius
        font_face = "monofur",
        top_font_size = 26, -- font size for display
        min_font_size = 4,  -- min font for trail
        max_font_size = 16, -- max font fot trail
        max_alpha = .7,     -- max alpha for trail
        trail = 40,         -- size of trail
        main_color = {0xFFFFFF, 1}, --color of numbers
        trail_color = {0xf4f4f4, 1} --color of trail
    },

    {
        -- Draw the Hours
        arg = "time %H",
        xc = 200,
        yc = 150,
        r  = 60,
        font_face = "monofur",
        top_font_size = 58, -- font size for display
        min_font_size = 3,  -- min font for trail
        max_font_size = 12, -- max font fot trail
        max_alpha = .6,     -- max alpha for trail
        trail = 40,         -- size of trail
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

        cairo_select_font_face (cr, t.font_face, CAIRO_FONT_SLANT_NORMAL,  CAIRO_FONT_WEIGHT_NORMAL)

        local value = tonumber(conky_parse(string.format("${%s}",t.arg)))
        local first = value - t.trail

        if t.arg == 'time %H' then -- special case for the hour digit
             cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.main_color))
             cairo_set_font_size (cr, t.top_font_size)
             cairo_move_to(cr, t.xc - t.top_font_size/3, t.yc+t.top_font_size/4) -- minor adjustment. Tweak here for your setting
             cairo_show_text(cr, value)
        else
            for i = first, value do

                local theta = i*2*math.pi/60 -math.pi/2 -- calculate the angle
                local alpha = t.max_alpha*(i-first)/(value-first) -- map alpha value to [0, max_alpha]
                local font_size = (t.max_font_size-t.min_font_size)*(i-first)/(value-first) + t.min_font_size -- map font size similar to alpha
                t.trail_color[2] = alpha
                cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.trail_color))
                cairo_set_font_size (cr, font_size)
                if i == value then -- if we have the main value
                    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.main_color)) -- switch color
                    cairo_set_font_size (cr, t.top_font_size) -- switch font
                end -- end if
                local k = i
                if k < 0 then k = 60 + i end  -- adjust seconds
                cairo_move_to(cr, t.xc + t.r*math.cos(theta), t.yc + t.r*math.sin(theta))
                cairo_show_text(cr, k)

            end -- end for
        end --end if
end -- end draw_clock


function rgba_to_r_g_b_a(tcolor)
	local color,alpha=tcolor[1],tcolor[2]
	return ((color / 0x10000) % 0x100) / 255.,
		((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end --end rgba