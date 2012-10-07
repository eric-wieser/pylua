abs = function(x)
	if type(x) == "number" then
		return math.abs(x)
	else
		return x:__abs__()
	end
end

any = function(iterable)
	for v in iter(iterable) do
		if v then return true end
	end
	return false
end

all = function(iterable)
	for v in iter(iterable) do
		if not v then return false end
	end
	return true
end

callable = function(x)
	if type(x) == "function" then
		return true
	elseif getmetatable(x).__call then
		return true
	elseif x.__call__ then
		return true
	else
		return false
	end
end

id = function(o)
	return type(o) == "table" and o.__id__ or tonumber(tostring(o):sub(-8, -1), 16)
end

iter = function(o)
	if o.__iter__ then return o:__iter__() end
	local key, value
	return function()
		key, value = next(o, key)
		return value
	end
end

max = function(o, key)
	local best
	for v in iter(o) do
		if key then v = key(v) end
		if best == nil or v > best then best = v end
	end
	return best
end

min = function(o, key)
	local best
	for v in iter(o) do
		if key then v = key(v) end
		if best == nil or v < best then best = v end
	end
	return best
end

range = function(start, end_, step)
	if end_ == nil then start, end_ = 1, start end
	local x = {}
	for i = start, end_, step or 1 do x[i] = i end
	return x
end

repr = function(x)
	if type(x) == "string" then
		return ("%q"):format(x)
	elseif type(x) == "table" then
		local str = "{"
		local sep = ""
		for k, v in pairs(x) do
			str = str .. sep
			if type(k) == "string" and k:match('^[a-zA-Z]\w*$') then
				str = str .. k
			else
				str = str .. "[" .. repr(k) .."]"
			end
			str = str .. " = ".. repr(v)
			sep = ", "
		end
		return str.."}"
	else
		return tostring(x)
	end
end

super = function(type, instance)
	-- crap this is hard
end