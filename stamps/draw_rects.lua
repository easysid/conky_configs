--[[ lua script for stamps. no images
Sun, 30 Jun 2013 16:06:12 IST
written by easysid
]]--

require 'cairo'

function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, 
    conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    draw_gogg({
        x=0,    
        y=10,
        w=200,  -- width and height
        h=100,
        r = 3, -- radius of the outline 
        fill_color = {0x990012, 0.9}})
    draw_gogg({
        x=0,
        y=115,
        w=100,
        r=2,
        h=90,
        fill_color = {0x254117, 0.9}})
        
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end --end main()

function draw_gogg(t)
    local b = t.border or 5
    default_font = t.font or 'monospace'
    default_fs = t.fs or 16
    default_text_color = t.text_color or {0xffffff, 0.8}
    t.fill_color = t.fill_color or {0xff0000,0.8}
    t.r = t.r or math.floor(t.w/60)
    
    cairo_set_line_width(cr, 1)
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a({0xffffff, 0.6}))
    cairo_set_line_width(cr, 2)
    cairo_rectangle(cr, t.x, t.y, t.w, t.h)
    cairo_fill(cr)
    cairo_save(cr)
    -- Start drawing the outline.
    cairo_set_operator(cr,CAIRO_OPERATOR_CLEAR)
    -- widthwise
    a = t.x+2*t.r
    while a < t.x+t.w do
        cairo_move_to(cr, a,t.y)
        cairo_arc(cr, a, t.y, t.r, 0, math.pi)
        cairo_move_to(cr, a,t.y+t.h)
        cairo_arc(cr, a, t.y+t.h, t.r, math.pi, 0)
        a = a+3*t.r
    end
        cairo_fill(cr)
    --heightwise    
    a = t.y+2*t.r
    while a < t.y+t.h do
        cairo_move_to(cr, t.x, a)
        cairo_arc(cr, t.x, a, t.r, -math.pi/2, math.pi/2)
        cairo_move_to(cr, t.x+t.w, a)
        cairo_arc(cr, t.x+t.w, a, t.r, math.pi/2, -math.pi/2)
        a = a+3*t.r
    end
    cairo_fill(cr)
    cairo_restore(cr)
    
    --fill with color
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(t.fill_color))
    cairo_set_line_width(cr, 2)
    cairo_rectangle(cr, t.x+b, t.y+b, t.w-2*b, t.h-2*b)
    cairo_fill(cr)  
    
end

function rgba_to_r_g_b_a(tcolor)
    local color,alpha=tcolor[1],tcolor[2]
    return ((color / 0x10000) % 0x100) / 255., 
        ((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end --end rgba
