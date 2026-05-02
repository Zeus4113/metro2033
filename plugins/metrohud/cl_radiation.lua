if not CLIENT then return end

local GAIN_MAX = 20
local GAIN_THRESHOLD = 10 -- halfway point

-- =========================
-- Mechanical State Per Gauge
-- =========================

local GaugeState = {
    radiation = {
        smooth = 0,
        velocity = 0
    },
    gain = {
        smooth = 0,
        velocity = 0
    }
}

-- =========================
-- Helper
-- =========================

function draw.Circle(x, y, radius, seg)
    local cir = {}
    table.insert(cir, { x = x, y = y })

    for i = 0, seg do
        local a = math.rad((i / seg) * -360)
        table.insert(cir, {
            x = x + math.sin(a) * radius,
            y = y + math.cos(a) * radius
        })
    end

    surface.DrawPoly(cir)
end

-- =========================
-- Curved Stat Bar
-- =========================

local function DrawCurvedStatBar(centerX, centerY, radius, startAngle, endAngle, value, max, barColor, reverseFill)
    local frac = math.Clamp(value / max, 0, 1)
    local fillAngle

    if reverseFill then
        fillAngle = Lerp(1 - frac, startAngle, endAngle)
    else
        fillAngle = Lerp(frac, startAngle, endAngle)
    end

    local segments = 30
    local barWidth = 8
    local gap = 1
    local innerRadius = radius + gap
    local outerRadius = innerRadius + barWidth
    local borderInner = innerRadius - 1.5
    local borderOuter = outerRadius + 1.5

    local function BuildArc(radiusValue, aStart, aEnd)
        local points = {}
        for i = 0, segments do
            local t = i / segments
            local ang = math.rad(Lerp(t, aStart, aEnd))
            points[#points + 1] = {
                x = centerX + math.cos(ang) * radiusValue,
                y = centerY + math.sin(ang) * radiusValue
            }
        end
        return points
    end

    local outerPoints = BuildArc(outerRadius, startAngle, endAngle)
    local innerPoints = BuildArc(innerRadius, startAngle, endAngle)
    local borderOuterPoints = BuildArc(borderOuter, startAngle - 1, endAngle + 1.5)
    local borderInnerPoints = BuildArc(borderInner, startAngle - 1, endAngle + 1.5)

    draw.NoTexture()
    surface.SetDrawColor(15, 15, 15, 240)
    for i = 1, segments do
        surface.DrawPoly({
            borderOuterPoints[i],
            borderOuterPoints[i + 1],
            borderInnerPoints[i + 1],
            borderInnerPoints[i]
        })
    end

    -- border end caps
    surface.DrawPoly({
        borderOuterPoints[1],
        outerPoints[1],
        innerPoints[1],
        borderInnerPoints[1]
    })
    surface.DrawPoly({
        borderOuterPoints[#borderOuterPoints],
        outerPoints[#outerPoints],
        innerPoints[#innerPoints],
        borderInnerPoints[#borderInnerPoints]
    })

    surface.SetDrawColor(55, 55, 55, 220)
    for i = 1, segments do
        surface.DrawPoly({
            outerPoints[i],
            outerPoints[i + 1],
            innerPoints[i + 1],
            innerPoints[i]
        })
    end

    if frac > 0 then
        local fillStart = reverseFill and fillAngle or startAngle
        local fillEnd = reverseFill and endAngle or fillAngle
        local borderFillOuter = BuildArc(outerRadius + 1, fillStart, fillEnd)
        local borderFillInner = BuildArc(innerRadius - 1, fillStart, fillEnd)

        surface.SetDrawColor(15, 15, 15, 220)
        for i = 1, #borderFillOuter - 1 do
            surface.DrawPoly({
                borderFillOuter[i],
                borderFillOuter[i + 1],
                borderFillInner[i + 1],
                borderFillInner[i]
            })
        end

        -- fill end caps
        surface.DrawPoly({
            borderFillOuter[1],
            borderFillOuter[2],
            borderFillInner[2],
            borderFillInner[1]
        })
        surface.DrawPoly({
            borderFillOuter[#borderFillOuter],
            borderFillOuter[#borderFillOuter - 1],
            borderFillInner[#borderFillInner - 1],
            borderFillInner[#borderFillInner]
        })

        local outerFill = BuildArc(outerRadius - 1, fillStart, fillEnd)
        local innerFill = BuildArc(innerRadius + 1, fillStart, fillEnd)

        surface.SetDrawColor(barColor.r, barColor.g, barColor.b, 220)
        for i = 1, #outerFill - 1 do
            surface.DrawPoly({
                outerFill[i],
                outerFill[i + 1],
                innerFill[i + 1],
                innerFill[i]
            })
        end
    end
end

-- =========================
-- Draw Function
-- =========================

local function DrawMetroWatch(id, x, y, size, value, max, threshold, wedgeColor, label)
  
    local centerX = x + size / 2
    local centerY = y + size / 2
    local radius = size / 2

    local targetFrac = math.Clamp(value / max, 0, 1)

    -- Mechanical inertia
    local state = GaugeState[id]
    if not state then return end

    local targetFrac = math.Clamp(value / max, 0, 1)

    local inertiaStrength = 8
    local damping = 0.92

    -- Gain gauge reacts faster
    if id == "gain" then
        inertiaStrength = 14
        damping = 0.85
    end

    local diff = targetFrac - state.smooth
    state.velocity = state.velocity + diff * inertiaStrength * FrameTime()
    state.velocity = state.velocity * damping
    state.smooth = math.Clamp(state.smooth + state.velocity, 0, 1)

    if id == "gain" and value > 0 then
        state.smooth = state.smooth + math.Rand(-0.01, 0.01)
    end

    local startAngle = 140
    local endAngle = 400
    local needleAngleDeg = Lerp(state.smooth, startAngle, endAngle)

    -- =========================
    -- Casing
    -- =========================F

    draw.NoTexture()
    surface.SetDrawColor(45, 45, 45, 255)
    draw.Circle(centerX, centerY, radius, 64)

    -- Inner face
    surface.SetDrawColor(wedgeColor.r, wedgeColor.g, wedgeColor.b, 180)
    draw.Circle(centerX, centerY, radius - 8, 64)

    -- =========================
    -- Green Safe Wedge
    -- =========================

    local thresholdAngle = Lerp(threshold / max, startAngle, endAngle)
    local dangerSpan = endAngle - thresholdAngle
    local yellowSpan = dangerSpan * 0.5
    local yellowStart = thresholdAngle - yellowSpan

    if startAngle < yellowStart then
        surface.SetDrawColor(100, 180, 100, 140)

        local segments = 40
        local poly = {}
        table.insert(poly, { x = centerX, y = centerY })

        for i = 0, segments do
            local t = i / segments
            local ang = math.rad(Lerp(t, startAngle, yellowStart))
            table.insert(poly, {
                x = centerX + math.cos(ang) * (radius - 14),
                y = centerY + math.sin(ang) * (radius - 14)
            })
        end

        surface.DrawPoly(poly)
    end

    -- =========================
    -- Yellow Warning Wedge
    -- =========================

    local yellowEnd = thresholdAngle

    if yellowStart < yellowEnd then
        surface.SetDrawColor(180, 180, 90, 140)

        local segments = 40
        local poly = {}
        table.insert(poly, { x = centerX, y = centerY })

        for i = 0, segments do
            local t = i / segments
            local ang = math.rad(Lerp(t, yellowStart, yellowEnd))
            table.insert(poly, {
                x = centerX + math.cos(ang) * (radius - 14),
                y = centerY + math.sin(ang) * (radius - 14)
            })
        end

        surface.DrawPoly(poly)
    end

    -- =========================
    -- Orange Radiation Wedge
    -- =========================

    if thresholdAngle < endAngle then
        surface.SetDrawColor(180, 120, 60, 140)

        local segments = 40
        local poly = {}
        table.insert(poly, { x = centerX, y = centerY })

        for i = 0, segments do
            local t = i / segments
            local ang = math.rad(Lerp(t, thresholdAngle, endAngle))
            table.insert(poly, {
                x = centerX + math.cos(ang) * (radius - 14),
                y = centerY + math.sin(ang) * (radius - 14)
            })
        end

        surface.DrawPoly(poly)
    end

    -- =========================
    -- Tick Marks + Numbers
    -- =========================

    local tickCount = 5
    for i = 0, tickCount do

        local frac = i / tickCount
        local angle = math.rad(Lerp(frac, startAngle, endAngle))

        -- Tick lines
        local inner = radius - 24
        local outer = radius - 10

        local x1 = centerX + math.cos(angle) * inner
        local y1 = centerY + math.sin(angle) * inner
        local x2 = centerX + math.cos(angle) * outer
        local y2 = centerY + math.sin(angle) * outer

        surface.SetDrawColor(25, 25, 25, 255)
        surface.DrawLine(x1, y1, x2, y2)

        -- Numbers
        local value = math.Round(max * frac)

        local textRadius = radius - 38
        local tx = centerX + math.cos(angle) * textRadius
        local ty = centerY + math.sin(angle) * textRadius

        draw.SimpleText(
            value,
            "DermaDefaultBold",
            tx,
            ty,
            Color(30, 30, 30),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    -- =========================
    -- Needle
    -- =========================

    local jitter = 0
    if state.smooth > (threshold / max) then
        jitter = math.sin(CurTime() * 25) * (state.smooth * 2)
    end

    local needleAngle = math.rad(needleAngleDeg + jitter)
    local needleLength = radius - 26
    local needleWidth = 2.5
    local perpAngle = needleAngle + math.pi / 2
    local offX = math.cos(perpAngle) * (needleWidth / 2)
    local offY = math.sin(perpAngle) * (needleWidth / 2)

    local nx = centerX + math.cos(needleAngle) * needleLength
    local ny = centerY + math.sin(needleAngle) * needleLength

    surface.SetDrawColor(20, 20, 20, 255)
    surface.DrawPoly({
        { x = centerX + offX, y = centerY + offY },
        { x = centerX - offX, y = centerY - offY },
        { x = nx - offX, y = ny - offY },
        { x = nx + offX, y = ny + offY }
    })

    draw.RoundedBox(8, centerX - 6, centerY - 6, 12, 12, Color(40, 40, 40))

    -- =========================
    -- Separate LED Casing Bump
    -- =========================

    local bumpSize = 22
    local bumpX = x - 12
    local bumpY = y + size - bumpSize + 12

    -- Metal bump housing
    draw.RoundedBox(6, bumpX, bumpY, bumpSize, bumpSize, Color(50, 50, 50))

    -- LED light
    local danger = (value >= (threshold * 0.66))

    if danger then
        local pulse = 150 + math.sin(CurTime() * 10) * 80
        draw.RoundedBox(
            8,
            bumpX + 6,
            bumpY + 6,
            10,
            10,
            Color(255, 80, 20, pulse)
        )
    else
        draw.RoundedBox(
            8,
            bumpX + 6,
            bumpY + 6,
            10,
            10,
            Color(90, 30, 20)
        )
    end

    -- =========================
    -- Adds label
    -- =========================

    if label then
        local labelY = centerY + radius * 0.52

        -- tiny soft shadow
        draw.SimpleText(
            label,
            "DermaDefaultBold",
            centerX + 1,
            labelY + 1,
            Color(0, 0, 0, 25),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )

        -- main engraved text
        draw.SimpleText(
            label,
            "DermaDefaultBold",
            centerX,
            labelY,
            Color(60, 50, 25),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end
end

-- =========================
-- HUD Hook
-- =========================

function PLUGIN:DrawRadiationWatch(char)

    local centerX = ScrW() - 130
    local centerY = ScrH() - 130
    local radius = 100

    local radiation = char:GetData("radiation", 0)
    local max = ix.config.Get("radiationMax", 100)
    local threshold = ix.config.Get("radiationThreshold", 60)

    -- MAIN RADIATION GAUGE
    DrawMetroWatch(
        "radiation",
        centerX - 100,
        centerY - 100,
        200,
        radiation,
        max,
        threshold,
        Color(204, 224, 203),
        "RAD"
    )

    local client = char:GetPlayer()

    -- Draw stat bars around the gauge
    local health = client:Health()
    local maxHealth = client:GetMaxHealth()

    -- Try to get stamina, hunger, thirst from character data
    local stamina = client:GetLocalVar("stm", 0)
    local maxStamina = 100
    local hunger = char:GetHunger()
    local maxHunger = 100
    local thirst = char:GetThirst()
    local maxThirst = 100
    
    -- Left side bars
    DrawCurvedStatBar(centerX, centerY, radius + 4, 95, 175, health, maxHealth, Color(220, 50, 50), true)
    DrawCurvedStatBar(centerX, centerY, radius + 4, 185, 265, stamina, maxStamina, Color(240, 220, 25), false)

    -- Right side bars
    DrawCurvedStatBar(centerX, centerY, radius + 4, 275, 355, hunger, maxHunger, Color(60, 200, 100), true)
    DrawCurvedStatBar(centerX, centerY, radius + 4, 5, 85, thirst, maxThirst, Color(80, 140, 240), false)

    local hasDosimeter = false
    hasDosimeter = true
end