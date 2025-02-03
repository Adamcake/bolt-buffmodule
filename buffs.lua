-- converts a number in the range 0-1 to an integer in the range 0-255
local function roundcol (c)
  return math.floor((c * 255.0) + 0.5)
end

return {
  -- startindex should be the index immediately after the image that's suspected of being a buff,
  -- or 1 if the suspected buff was seen in a previous event (i.e. onrendericon).
  -- first returned value is true if it's actually a buff, false if not.
  -- if true, second value will be the number shown on the buff (or nil if no number is shown),
  -- and third value will be the number shown after that in parentheses (or nil if none).
  -- the number may or may not be an amount of time, depending on the buff, but regardless, this
  -- function will multiply it by 60 for 'm' or 3600 for 'hr' if those appear in the text.
  tryreadbuffdetails = function (this, event, startindex, pxleft, pxtop, isbuff)
    local vertexcount = event:vertexcount()
    local verticesperimage = event:verticesperimage()
    local buffnumber = nil
    local parensnumber = nil
    local skipnumber = false

    local boxr = isbuff and 90 or 204
    local boxg = isbuff and 150 or 0
    local boxb = isbuff and 25 or 0

    for i = startindex, vertexcount, verticesperimage do
      if skipnumber then
        skipnumber = false
        goto continue
      end

      local ax, ay, aw, ah, _, _ = event:vertexatlasdetails(i)
      local u, v = event:vertexuv(i)
      if u == nil or v == nil then
        local x, y = event:vertexxy(i + 2)
        local fr, fg, fb = event:vertexcolour(i)
        if x == pxleft and y == pxtop and roundcol(fr) == boxr and roundcol(fg) == boxg and roundcol(fb) == boxb then
          return true, buffnumber, parensnumber
        end
        return false
      end

      if ah <= 6 then return false end
      local char = this.buffchars[event:texturedata(ax, ay + 6, aw * 4)]
      if type(char) == "table" then
        char = char[event:texturedata(ax, ay + 1, aw * 4)]
      end
      if not char then return false end
      skipnumber = true

      if type(char) == "number" then
        if parensnumber ~= nil then
          parensnumber = char + (parensnumber * 10)
        elseif buffnumber ~= nil then
          buffnumber = char + (buffnumber * 10)
        else
          buffnumber = char
        end
      end

      if char == 'h' then
        if parensnumber ~= nil then
          parensnumber = parensnumber * 3600
        elseif buffnumber ~= nil then
          buffnumber = buffnumber * 3600
        end
      elseif char == 'm' then
        if parensnumber ~= nil then
          parensnumber = parensnumber * 60
        elseif buffnumber ~= nil then
          buffnumber = buffnumber * 60
        end
      elseif char == '(' and parensnumber == nil then
        parensnumber = 0
      end
      ::continue::
    end
    return false
  end,

  -- lookup table of the 7th row (1-indexed, so y+6) of pixels in each character that can appear written on a buff or debuff.
  -- if the result is a table, it's a table of the 2nd row (y+1).
  -- four different fonts can appear depending on user settings and the amount of characters being rendered, and heights vary.
  buffchars = {
    ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"] = 0,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\x88\xff\xff\xff\x88\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x44\xff\xff\xff\x44\x00\x00\x01\x00\x00\x00\x01\x00"] = 0,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x22\xff\xff\xff\x22\xff\xff\xff\xaa\xff\xff\xff\xaa\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\x22\xff\xff\xff\x22\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 0,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x77\xff\xff\xff\x77\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\x11\xff\xff\xff\x11\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 0,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"] = 1,
    ["\xff\xff\xff\x44\xff\xff\xff\x44\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x77\xff\xff\xff\x77\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 1,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x44\xff\xff\xff\x44\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xdd\xff\xff\xff\xdd\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 1,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x55\xff\xff\xff\x55\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x44\xff\xff\xff\x44\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 1,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = 2,
    ["\xff\xff\xff\x77\xff\xff\xff\x77\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xaa\xff\xff\xff\xaa\x00\x00\x01\x00\x00\x00\x01\x00"] = 2,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x44\xff\xff\xff\x44\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\x77\xff\xff\xff\x77\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 2,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x22\xff\xff\xff\x22\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\x66\xff\xff\xff\x66\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 2,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = 3,
    ["\xff\xff\xff\x44\xff\xff\xff\x44\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x66\xff\xff\xff\x66\x00\x00\x01\x00\x00\x00\x01\x00"] = 3,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xaa\xff\xff\xff\xaa\x00\x00\x01\x00\x00\x00\x01\x00"] = 3,
    ["\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 3,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"] = 4,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 4,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x88\xff\xff\xff\x88\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\x22\xff\xff\xff\x22\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 4,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x11\xff\xff\xff\x11\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 4,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = {
      ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"] = 5,
      ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = 'h',
    },
    ["\xff\xff\xff\x77\xff\xff\xff\x77\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x22\xff\xff\xff\x22\x00\x00\x01\x00\x00\x00\x01\x00"] = 5,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\x33\xff\xff\xff\x33\x00\x00\x01\x00\x00\x00\x01\x00"] = 5,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x77\xff\xff\xff\x77\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x44\xff\xff\xff\x44\x00\x00\x01\x00\x00\x00\x01\x00"] = 5,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = 6,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x44\xff\xff\xff\x44\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\x77\xff\xff\xff\x77\xff\xff\xff\xaa\xff\xff\xff\xaa\xff\xff\xff\x22\xff\xff\xff\x22\x00\x00\x01\x00\x00\x00\x01\x00"] = 6,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x22\xff\xff\xff\x22\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\x33\xff\xff\xff\x33\x00\x00\x01\x00\x00\x00\x01\x00"] = 6,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\x55\xff\xff\xff\x55\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 6,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = 7,
    ["\xff\xff\xff\x55\xff\xff\xff\x55\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x66\xff\xff\xff\x66\x00\x00\x01\x00\x00\x00\x01\x00"] = 7,
    ["\xff\xff\xff\x88\xff\xff\xff\x88\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\x00\x00\x01\x00\x00\x00\x01\x00"] = 7,
    ["\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x01\x00\x00\x00\x01\x00"] = 7,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = 8,
    ["\xff\xff\xff\x55\xff\xff\xff\x55\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xaa\xff\xff\xff\xaa\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\x88\xff\xff\xff\x88\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xaa\xff\xff\xff\xaa\x00\x00\x01\x00\x00\x00\x01\x00"] = 8,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\x77\xff\xff\xff\x77\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 8,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x77\xff\xff\xff\x77\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xaa\xff\xff\xff\xaa\xff\xff\xff\x44\xff\xff\xff\x44\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 8,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"] = 9,
    ["\xff\xff\xff\x66\xff\xff\xff\x66\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\x88\xff\xff\xff\x88\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\x11\xff\xff\xff\x11\x00\x00\x01\x00\x00\x00\x01\x00"] = 9,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x44\xff\xff\xff\x44\xff\xff\xff\xbb\xff\xff\xff\xbb\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\x77\xff\xff\xff\x77\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 9,
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x22\xff\xff\xff\x22\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\x55\xff\xff\xff\x55\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 9,
    ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"] = 'm',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'm',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'm',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'm',
    ["\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x77\xff\xff\xff\x77\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'h',
    ["\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\xdd\xff\xff\xff\x22\xff\xff\xff\x22\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'h',
    ["\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x44\xff\xff\xff\x44\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'h',
    ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = 'r',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'r',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'r',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = 'r',
    ["\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"] = '(',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xbb\xff\xff\xff\xbb\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00"] = '(',
    ["\xff\xff\xff\x22\xff\xff\xff\x22\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x33\xff\xff\xff\x33\x00\x00\x01\x00\x00\x00\x01\x00"] = '(',
    ["\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"] = '%',
    ["\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x88\xff\xff\xff\x88\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\xaa\xff\xff\xff\xaa\xff\xff\xff\x11\xff\xff\xff\x11\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x88\xff\xff\xff\x88\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\x33\xff\xff\xff\x33\x00\x00\x01\x00\x00\x00\x01\x00"] = '%',
    ["\xff\xff\xff\x11\xff\xff\xff\x11\xff\xff\xff\x99\xff\xff\xff\x99\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xee\xff\xff\xff\xee\xff\xff\xff\x77\xff\xff\xff\x77\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\xff\xff\xff\x33\xff\xff\xff\x33\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xcc\xff\xff\xff\xcc\xff\xff\xff\x11\xff\xff\xff\x11\x00\x00\x01\x00\x00\x00\x01\x00"] = '%',
  },
}
