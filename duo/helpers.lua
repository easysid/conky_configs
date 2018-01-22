--[[
helpers.lua
helper functions for conky configs
easysid
* Monday, 22 January 2018 20:36 IST
    - added put_image()
* Friday, 12 January 2018 15:21 IST
    - Initial commit

Functions
* put_text({x, y, c, f, fs, face, txt, hj, vj})
* put_image({x, y, file, w, h})
* get_text_extents(txt, f, fs, face)
* get_accuweather(url)
* normalize(value, min, max)
* scale(value, a, b, x, y) -- map a value from [a, b] to [x, y]
* draw_circle({x, y, r, start, ends, border, border_color, fill_color})
* rgba_to_r_g_b_a({color, alpha})
]]


function get_text_extents(txt, f, fs, face)
    -- text, font, font size, weight/slant
    local extents = cairo_text_extents_t:create()
    tolua.takeownership(extents)
    if face == "normal" then
        face = {f, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL}
    elseif face == "bold" then
        face = {f, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD}
    elseif face == "italic" then
        face = {f, CAIRO_FONT_SLANT_ITALIC, CAIRO_FONT_WEIGHT_NORMAL}
    elseif face == "bolditalic" then
        face = {f, CAIRO_FONT_SLANT_ITALIC, CAIRO_FONT_WEIGHT_BOLD}
    else
        face = {f, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL}
        print('face not set - "normal", "bold", "italic", "bolditalic"')
        print('falling back to using "normal"')
    end
    cairo_select_font_face(cr, face[1], face[2], face[3])
    cairo_set_font_size(cr, fs)
    cairo_text_extents(cr, txt, extents)
    return extents
end -- function text_extents

function put_text(txj)
    --Taken from mrpeachy's wun.lua
    --args: c, a, f, fs, face, x, y, txt, hj, vj

    local function justify(jtxt, x, hj, y, vj, f, face, fs)
        local extents= get_text_extents(jtxt, f, fs, face)
        if face == "normal" then
            face = {f, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL}
        elseif face == "bold" then
            face = {f, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD}
        elseif face == "italic" then
            face = {f, CAIRO_FONT_SLANT_ITALIC, CAIRO_FONT_WEIGHT_NORMAL}
        elseif face == "bolditalic" then
            face = {f, CAIRO_FONT_SLANT_ITALIC, CAIRO_FONT_WEIGHT_BOLD}
        else
            print('face not set - "normal", "bold", "italic", "bolditalic"')
        end
        local wx = extents.x_advance
        local wd = extents.width
        local hy = extents.height
        local bx = extents.x_bearing
        local by = extents.y_bearing+hy
        local tx = x
        local ty = y
        -- set horizontal alignment - left, centre, right
        if hj == "l" then
            x = x-bx
        elseif hj == "c" then
            x = x-((wx-bx)/2)-bx
        elseif hj == "r" then
            x = x-wx
        else
            print("hj not set correctly - l, c, r")
        end
        -- vertical - normal, normal-ybearing, middle, middle-ybearing, top
        if vj == "n" then
            y = y
        elseif vj == "nb" then
            y = y-by
        elseif vj == "m" then
            y = y+((hy-by)/2)
        elseif vj == "mb" then
            y = y+(hy/2)-by
        elseif vj == "t" then
            y = y+hy-by
        else
            print("vj not set correctly - n, nb, m, mb, t")
        end
        return face, fs, x, y, tx, ty
    end -- function justify

    -- set variables
    local  c    = txj.c     or  {0xffffff, 1}
    local  f    = txj.f     or  "monospace"
    local  fs   = txj.fs    or  12
    local  x    = txj.x     or  10
    local  y    = txj.y     or  10
    local  txt  = txj.txt   or  "text not set"
    local  hj   = txj.hj    or  "l"
    local  vj   = txj.vj    or  "n"
    local  face = txj.face  or  "normal"
    -- print text
    local face, fs, x, y = justify(txt, x, hj, y, vj, f, face, fs)
    cairo_select_font_face(cr, face[1], face[2], face[3])
    cairo_set_font_size(cr, fs)
    cairo_move_to(cr, x, y)
    cairo_set_source_rgba(cr, rgba_to_r_g_b_a(c))
    cairo_show_text(cr, txt)
    cairo_stroke(cr)
end --function put_text

function put_image(t)
    local image = imlib_load_image(t.file)
    if image == nil then
        print("Unable to load image", t.file)
        return
    end
    imlib_context_set_image(image)
    local img_w  = imlib_image_get_width()
    local img_h  = imlib_image_get_height()
    local x      = t.x or  100
    local y      = t.y or  100
    local w      = t.w or  img_w
    local h      = t.h or  img_h
    local hj     = t.hj or 'l'
    local vj     = t.vj or 'b'
    if hj == 'c' then
        x = x - w/2
    elseif hj == 'r' then
        x = x - w
    end
    if vj == 'm' then
        y = y - h/2
    elseif vj == 't' then
        y = y - h
    end
    local scaled = imlib_create_cropped_scaled_image(0, 0, img_w, img_h, w, h)
    imlib_free_image()
    imlib_context_set_image(scaled)
    imlib_render_image_on_drawable(x, y)
    imlib_free_image()
    image = nil
end

function get_accuweather(url)
    -- use the current weather url
    url = string.gsub(url, "weather%-forecast", "current-weather")
    local agent = "User-Agent:Mozilla/5.0 Chrome/57.0.2987.133 Safari/537.36"
    local f = io.popen(
                string.format("curl --max-time 60 -H '%s' '%s'", agent, url)
                )
    local data = f:read("*a")
    f:close()
    local location = string.match(data, '<div class="display-name">(.-)</div>')
    local current  = string.match(data, 'cu: {.-}')
    local temp     = tonumber(string.match(current, "rf : '(.-)'"))
    local icon     = string.match(current, "wx : '(.-)'")
    local cond     = string.match(current, "txt : '(.-)'")
    return {temp=temp, icon=icon, cond=cond, location=location}
end -- function get_accuweather

function normalize(value, min ,max)
    -- normalize a value to [min, max]
    return (value - min)/(max - min)
end --function normalize

function scale(value, a, b, x, y)
    -- map a value from [a, b] to [x, y]
    return value*(y - x)/(b - a)
end -- function scale

function draw_circle(t)
    -- args - x, y, radius, start angle, end angle,
    --        border width, border_color, fill_color
    -- setup defaults
    local x = t.x or 10
    local y = t.y or 10
    local radius = t.r or 20
    local start = t.start or 0
    local ends = t.ends or 2*math.pi
    local border = t.border_width or 1
    -- end setup
    cairo_set_line_width(cr, border)
    if t.border_color then
        cairo_set_source_rgba(cr, rgba_to_r_g_b_a(t.border_color))
        cairo_arc(cr, x, y, radius, start, ends)
        cairo_stroke(cr)
    end
    if t.fill_color then
        cairo_set_source_rgba(cr, rgba_to_r_g_b_a(t.fill_color))
        cairo_arc(cr, x, y, radius, start, ends)
        cairo_fill(cr)
    end
end -- function draw_circle

function rgba_to_r_g_b_a(tcolor)
    local color, alpha = tcolor[1], tcolor[2]
    return((color / 0x10000) % 0x100) / 255.,
       ((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end -- function rgba

