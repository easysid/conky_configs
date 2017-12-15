--[[
dinaj.lua
lua script for Do I need a Jacket Conky
easysid
Thursday, 05 January 2017 13:22 IST

Based on the dinaj Rainmeter skin by FlyingHyrax

Credits:
* FlyingHyrax (http://flyinghyrax.deviantart.com)
* https://doineedajacket.com/
* mrpeachy, for the out() function

Updated:
Tuesday, 10 January 2017 16:28 IST
--]]

require 'cairo'

-- replace with your accuweather url. Be sure to use the current-weather url
local url = "https://www.accuweather.com/en/in/delhi/202396/current-weather/202396"

-- update frequency (in conky cycles)
local update_time = 600

-- testing flag. Prints fetched temperature onto the console.
local testing = 1

-- settings table. customize as per your liking
-- default ranges are in degrees Celcius
local t = {
    -- temperature settings
    JacketThreshold = 15,    -- minimum temperature to require a jacket
    CoatThreshold   = 3,     -- minimum temperature to require a coat
    unit = "C",              -- degrees Celcius (Use 'F' for Fahrenheit)
    -- text settings
    font  = "sans",    -- font face for the text
    color = {0xf0f0f0, 1},   -- {hex, alpha}
    -- line 1 - Do you need a jacket
    l1 = {
        font_size = 35,      -- font size
        x = 10,              -- x position of text
        y = 30
    },
    -- line 2 - outside conditions
    l2 = {
        font_size = 23,      -- font size
        x = 20,              -- x position of text
        y = 70
    },
} -- end settings table


--[[ You should not need to edit below this line ]]

local Constants = {
    RANGE_MIN = -30,
    RANGE_MAX = 50,
    ADJECTIVES = {
        "damn cold",
        "darn cold",
        "bone chilling",
        "glacial",
        "frigid",
        "freezing",
        "frosty",
        "pretty cold",
        "chilly",
        "brisk",
        "cool",
        "quite temperate",
        "rather mild",
        "pretty nice",
        "positively balmy",
        "extra warm",
        "kinda hot",
        "roasting",
        "scorching",
        "oven-like",
        "like your hair is on FIRE",
    }
}

local first_run = 1


-- main function.
function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display,
    conky_window.drawable, conky_window.visual,
    conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    local updates = tonumber(conky_parse('${updates}'))
    local timer = updates % update_time
    -- time the fetch data
    if timer == 0 or first_run == 1 then
        first_run = nil
        temperature = fetchData()
        if testing then
             print("\nTesting Mode. Current temperature", temperature)
        end
    end
    doINeedAJacket(temperature)
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end

-- fetch the webpage, and get the current temperature
function fetchData()
    -- use the current weather url
    url = string.gsub(url, "weather%-forecast", "current-weather")
    local regex = '"small.temp"><em>RealFeel.*</em>%s(-?%d+).-</span>'
    local temp = nil
    local agent = 'User-Agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36'
    local f = io.popen(string.format("curl --max-time 60 -H '%s' '%s'", agent, url))
    local data = f:read("*a")
    f:close()
    temp = string.match(data, regex)
    return tonumber(temp)
end

function doINeedAJacket(temp)
    if temp then
        local s1 = getMainString(temp)
        local s2 = getSubString(temp, t.unit)
        out({x=t.l1.x, y=t.l1.y, fs=t.l1.font_size, f=t.font, c=t.color, txt=s1})
        out({x=t.l2.x, y=t.l2.y, fs=t.l2.font_size, f=t.font, c=t.color, txt=s2})
    else
        out({x=10,y=10,txt="Failed to get current weather information"})
    end
end

-- Keeps a value inside the given range
function clamp(value, min, max)
    local clamped = value
    if value < min then
        clamped = min
    elseif value > max then
        clamped = max
    end
    return clamped
end

-- Adjusts a value and its defined range if the value is negative
function normalize(value, min, max)
    local excess = min < 0 and 0 - min or 0
    return value + excess, min + excess, max + excess
end

-- Return a value as a percentage of its range
function percentOfRange(value, min, max)
    -- normalize
    local value, min, max = normalize(value, min, max)
    -- maths
    local percent = (value / max - min)
    -- clamping
    return clamp(percent, 0.0, 1.0)
end

-- Convert a number from celsius to fahrenheit
function c2f(celsius)
    return (((celsius * 9) / 5) + 32)
end

-- Return a descriptor for the given temperature and scale
function getTempWord(temp, unit)
    -- convert our range bounds to fahrenheit if necessary
    local unit = unit or 'C'
    local tmin = unit == 'C' and Constants.RANGE_MIN or c2f(Constants.RANGE_MIN)
    local tmax = unit == 'C' and Constants.RANGE_MAX or c2f(Constants.RANGE_MAX)
    -- percentage of our temperature range
    local tempPer = percentOfRange(temp, tmin, tmax)
    -- index in array of descriptors, based on that percentage
    local index = math.ceil(#Constants.ADJECTIVES * tempPer)
    -- if temp is 0% of our range, index will be off by one
    if index < 1 then index = 1 end
    -- return that word
    return Constants.ADJECTIVES[index]
end

-- Answer the question
function getMainString(temp)
    local negation = (temp > t.JacketThreshold) and " don't" or ""
    local outerwear = (temp < t.CoatThreshold) and "coat" or "jacket"
    return string.format("You%s need a %s", negation, outerwear)
end

-- Return the appropriate secondary string
function getSubString(temp, unit)
    return string.format("It's %s outside", getTempWord(temp, unit))
end

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
            print ('face not set correctly - "normal","bold","italic","bolditalic"')
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

-- Log the descriptor which is returned for various temperatures
local function selftest()
    for i = -30, 55, 4 do
        -- print(string.format("t=%d, s=%s", i, getTempWord(i)))
        print(string.format("\nt=%d:\n%s\n%s\n", i,
        getMainString(i), getSubString(i, t.unit)))
    end
end

