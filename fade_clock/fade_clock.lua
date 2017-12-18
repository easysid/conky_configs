--[[
fade_clock.lua
lua script for fade_clock conky
easysid
Sunday, 17 December 2017 15:57 IST

Based on the Fade Rainmeter Skin by FreakQuency85 (http://fav.me/d2sd40n)

Credits:
* mrpeachy, for the out() function
* rainmeter skin http://fav.me/d2sd40n
--]]

require 'cairo'

--
-- There are two tables
-- settings_t1 draws the date, and time
-- settings_t2 draws the day, and month
--

-- Global settings. These are overrriden by element specific settings
default_font = 'sans'               -- font
default_text_color = {0x5dacba, 1}  -- color for the actual text
default_base_color = {0x404040, 1}  -- color for the trail


settings_t1 = { -- This table draws the vertical text - date and time
    {
    arg='%d',                       -- date. See man date, or strftime
    max = 31,                       -- maximum value
    x = 400,                        -- x position
    y = 520,                        -- y position
--    font = 'sans',                -- font face. Uncomment to override default_font
    size = 25,                      -- font size
--    text_color = {0x5dacba, 1},   -- color for the actual text. Uncomment to override default_text_color
--    base_color = {0x404040, 1},   -- color for the trail. Uncomment to override default_base_color
    trail = 7,                      -- number of trail after the text
    trail_back = nil;               -- trail before text. nil value means all the remaining trail
    },
    {
    arg='%I',                       -- hours in 12hr format. See man date, or strftime
    max = 12,
    x = 950,
    y = 200,
    size = 60,
    base_color = {0x202020, 0.7},   -- element specific color for the trail
    justify='r',                    -- text justification - right (default left)
    trail = 2,
    trail_back = 2;
    },
    {
    arg='%M',                       -- Minutes. See man date, or strftime
    max = 60,
    x = 980,
    y = 200,
    size = 60,
    base_color = {0x202020, 0.7},
    trail = 2,
    trail_back = 2;
    },
    {
    arg='%p',                       -- AM/PM. See man date, or strftime
    x = 1070,
    y = 200,
    size = 60,
    trail = nil,                    -- Do not draw the trail. Important
    },
    {
    arg=':',                        -- just the ':' separator
    x = 962,
    y = 196,
    size = 60,
    trail = nil,                    -- Do not draw the trail. Important
    }
} -- end settings_t1

settings_t2 = { -- This table draws the horizontal text - day, and month
    {
    arg='%m',                       -- month in decimal format. See man date, or strftime
    max=12,
    x = 440,
    y = 520,
    size = 26,
    trail = 44,
    left_pad = 60,                  -- left side padding to make space for date
    -- translate the following table for your own language
    names = {"JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY",
                "AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"}
    },
    {
    arg='%u',                       -- day of the week. See man date, or strftime
    max=7,
    x = 440,
    y = 560,
    size = 38,
    trail = 27,
    left_pad = 60,                  -- left side padding to make space for date
    -- translate the following table for your own language
    names = {"SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY",
                "THURSDAY", "FRIDAY", "SATURDAY"}
    }
} -- end settings_t2

-- ********** You should not need to change anything below this **********


-- main function.
function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display,
    conky_window.drawable, conky_window.visual,
    conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    local updates = tonumber(conky_parse('${updates}'))
    if updates > 2 then
        -- drawing code here
        for i in ipairs(settings_t1) do
            draw_datetime(settings_t1[i])
        end --for
        for i in ipairs(settings_t2) do
            draw_daymonth(settings_t2[i])
        end --for
        -- drawing code here
    end -- if
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end

function draw_datetime(t)
   local font = t.font or default_font
   local base_color = t.base_color or default_base_color
   local text_color = t.text_color or default_text_color
   local value = os.date(t.arg)
   -- draw main text
   out({x=t.x, y=t.y, fs=t.size, f=font, c=text_color, txt=value, hj=t.justify})
   -- calculate trail only if we have to
   if t.trail then
       local value = tonumber(value) or 0
       if not t.trail_back then t.trail_back = t.max - t.trail - 1 end
       -- magic number warning
       local dy = 1.2*get_extents(font, t.size, value, 'height')
       for i = 1, t.trail do                    -- draw forward trail
           local v = value + i
           if v > t.max then v = v%t.max end    -- fix out of bounds
           out({x=t.x, y=t.y+i*dy, fs=t.size, f=font, c=base_color,
                 txt=string.format('%02d', v), hj=t.justify})
       end
       for i = 1, t.trail_back  do              -- draw back trail
           local v = value - i
           if v < 1 then v = v + t.max end      -- fix negatives
           out({x=t.x, y=t.y-i*dy, fs=t.size, f=font, c=base_color,
                 txt=string.format('%02d', v), hj=t.justify})
       end
   end --end if
end --end draw_datetime

function draw_daymonth(t)
   local font = t.font or default_font
   local base_color = t.base_color or default_base_color
   local text_color = t.text_color or default_text_color
   local value = tonumber(os.date(t.arg))
   local s=''
   for i = value+1, #t.names do s = s..t.names[i] end -- join the next days
   for i = 1, value -1 do s = s..t.names[i] end       -- join the previous days
   local rhs = s:sub(1, t.trail)                      -- split the trail
   local lhs = s:sub(t.trail+1)
   s = t.names[value]
   local dx = get_extents(font, t.size, s, 'width')   -- check how wide is current day
   out({x=t.x, y=t.y, fs=t.size, f=font, c=text_color, txt=s})
   out({x=t.x+dx, y=t.y, fs=t.size, f=font, c=base_color, txt=rhs})
   out({x=t.x-t.left_pad, y=t.y, fs=t.size, f=font, c=base_color, txt=lhs, hj='r'})
end --end draw_daymonth

function get_extents(font, size, text, ext)
    local extents=cairo_text_extents_t:create()
    local e = 0
    tolua.takeownership(extents)
    cairo_select_font_face (cr,font)
    cairo_set_font_size(cr,size)
    cairo_text_extents(cr,text,extents)
    if ext == 'width' then
        e = extents.width
    else
        e = extents.height
    end
    return e
end --end get_extents

function out(txj)
   -- Taken from mrpeachy's wun.lua
   -- args: c,a,f,fs,face,x,y,txt,hj,vj,ro,sxo,syo,sfs,sface,sc,sa
    local extents=cairo_text_extents_t:create()
    tolua.takeownership(extents)
    local function justify(jtxt,x,hj,y,vj,f,face,fs)
        if face=="normal" then
            face={f,CAIRO_FONT_SLANT_NORMAL,CAIRO_FONT_WEIGHT_NORMAL}
        elseif face=="bold" then
            face={f,CAIRO_FONT_SLANT_NORMAL,CAIRO_FONT_WEIGHT_BOLD}
        elseif face=="italic" then
            face={f,CAIRO_FONT_SLANT_ITALIC,CAIRO_FONT_WEIGHT_NORMAL}
        elseif face=="bolditalic" then
            face={f,CAIRO_FONT_SLANT_ITALIC,CAIRO_FONT_WEIGHT_BOLD}
        else
            print ('face not set - "normal","bold","italic","bolditalic"')
        end
        cairo_select_font_face (cr,face[1],face[2],face[3])
        cairo_set_font_size(cr,fs)
        cairo_text_extents(cr,jtxt,extents)
        local wx=extents.x_advance
        local wd=extents.width
        local hy=extents.height
        local bx=extents.x_bearing
        local by=extents.y_bearing+hy
        local tx=x
        local ty=y
        --set horizontal alignment - l, c, r
        if hj=="l" then
            x=x-bx
        elseif hj=="c" then
            x=x-((wx-bx)/2)-bx
        elseif hj=="r" then
            x=x-wx
        else
            print ("hj not set correctly - l, c, r")
        end
        --vj. n=normal, nb=normal-ybearing, m=middle, mb=middle-ybearing, t=top
        if vj=="n" then
            y=y
        elseif vj=="nb" then
            y=y-by
        elseif vj=="m" then
            y=y+((hy-by)/2)
        elseif vj=="mb" then
            y=y+(hy/2)-by
        elseif vj=="t" then
            y=y+hy-by
        else
            print ("vj not set correctly - n, nb, m, mb, t")
        end
        return face,fs,x,y,rad,rad2,tx,ty
    end--justify local function #################
    --set variables
    local c=txj.c 			or {0xffffff, 1}
    local a=txj.a 			or 1
    local f=txj.f 			or "monospace"
    local fs=txj.fs 	    or 12
    local x=txj.x 		    or 100
    local y=txj.y 			or 100
    local txt=txj.txt 		or "text"
    local hj=txj.hj 		or "l"
    local vj=txj.vj 		or "n"
    local face=txj.face		or "normal"
    --print text ################################
    local face,fs,x,y=justify(txt,x,hj,y,vj,f,face,fs)
    cairo_select_font_face (cr,face[1],face[2],face[3])
    cairo_set_font_size(cr,fs)
    cairo_move_to (cr,x,y)
    cairo_set_source_rgba (cr,rgba_to_r_g_b_a(c))
    cairo_show_text (cr,txt)
    cairo_stroke (cr)
    return nx
end--function out

function rgba_to_r_g_b_a(tcolor)
    local color,alpha=tcolor[1],tcolor[2]
    return ((color / 0x10000) % 0x100) / 255.,
    ((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end --end rgba
