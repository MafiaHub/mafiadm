local function distanceSquared(pos1, pos2)
    return (pos1[1] - pos2[1]) ^ 2
        + (pos1[2] - pos2[2]) ^ 2
        + (pos1[3] - pos2[3]) ^ 2
end

local function distance(pos1, pos2)
    return math.sqrt(distanceSquared(pos1, pos2))
end

local function deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for origKey, origValue in next, orig, nil do
            copy[deepCopy(origKey)] = deepCopy(origValue)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function tableHasValue(table, value)
    if type(table) ~= "table" then
        return false
    end

    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

local function stringSplit(text)
    local chunks = {}
    for substring in text:gmatch("%S+") do
        table.insert(chunks, substring)
    end
    return chunks
end

local function stringCharAt(text, pos)
    return text:sub(pos, pos)
end

local function randomTableElem(tableArg)
    local seqTable = {}
    for _, elem in pairs(tableArg) do
        table.insert(seqTable, elem)
    end

    return seqTable[math.random(#seqTable)]
end

local function randomFloat(min, max)
    return min + ( max - min ) * math.random()
end

local function randomPointInCuboid(rect)
    local r1 = rect[1]
    local r2 = rect[2]

    return {
        randomFloat(r1[1], r2[1]),
        randomFloat(r1[2], r2[2]),
        randomFloat(r1[3], r2[3])
    }
end

local function isPointInCuboid(p, rect)
    local r1 = rect[1]
    local r2 = rect[2]
    
    local lowX = math.min(r1[1], r2[1])
    local lowY = math.min(r1[2], r2[2])
    local lowZ = math.min(r1[3], r2[3])
    local maxX = math.max(r1[1], r2[1])
    local maxY = math.max(r1[2], r2[2])
    local maxZ = math.max(r1[3], r2[3])

    return p[1] >= lowX and p[1] <= maxX and
        p[2] >= lowY and p[2] <= maxY and
        p[3] >= lowZ and p[3] <= maxZ
end

local function tableSlice(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end

    return sliced
end

local function addRandomVectorOffset(pos, maxOffset)
    return {
        pos[1] + (randomFloat(-maxOffset[1], maxOffset[1])),
        pos[2] + (randomFloat(-maxOffset[2], maxOffset[2])),
        pos[3] + (randomFloat(-maxOffset[3], maxOffset[3])),
    }
end

local function rgbToColor(r, g, b)
    local color = r
    color = (color << 8) + g
    color = (color << 8) + b

    return color
end

local function remapValue(value, startFrom, stopFrom, startTo, stopTo)
    return startTo + (stopTo - startTo) * ((value - startFrom) / (stopFrom - startFrom))
end

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function compareVectors(vec1, vec2)
    return vec1 and vec2 and vec1[1] == vec2[1] and vec1[2] == vec2[2] and vec1[3] == vec2[3]
end

local function tableAssign(...)
    local newTable = {}
    local arg = {...}

    for k, v in pairs(arg) do
        if type(v) == 'table' then
            for tk, tv in pairs(v) do
                newTable[tk] = tv
            end
        end
    end

    return newTable
end

local helpers = {
    distanceSquared = distanceSquared,
    distance = distance,
    deepCopy = deepCopy,
    tableHasValue = tableHasValue,
    stringSplit = stringSplit,
    stringCharAt = stringCharAt,
    randomFloat = randomFloat,
    randomTableElem = randomTableElem,
    randomPointInCuboid = randomPointInCuboid,
    tableSlice = tableSlice,
    isPointInCuboid = isPointInCuboid,
    addRandomVectorOffset = addRandomVectorOffset,
    rgbToColor = rgbToColor,
    remapValue = remapValue,
    dump = dump,
    compareVectors = compareVectors,
    tableAssign = tableAssign,
}

return helpers