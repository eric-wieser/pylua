--quick implementation of python's id function. Fails for built in roblox objects
require "builtins"
-- method resolution order, ported from the python spec
-- used to allow multiple inheritance

-- setmetatable(getfenv(), {
-- 	__newindex = function(t, k, v) print(k.." is global!"); return rawset(t, k, v) end
-- })

mro = (function()
	local isintail = function(cand, seqs)
		for _, seq in ipairs(seqs) do
			for i, item in ipairs(seq) do
				if i > 1 and item == cand then
					return true
				end
			end
		end
		return false
	end
	local merge = function(seqs)
		local res = {}
		while true do
			--filter out empty sequences
			local nonemptyseqs = {}
			for _, seq in ipairs(seqs) do
				if #seq > 0 then table.insert(nonemptyseqs, seq) end
			end
			--all sequences empty? we're done!
			if #nonemptyseqs == 0 then return res end

			-- find merge candidates among seq heads
			local cand
			for _, seq in ipairs(nonemptyseqs) do
				cand = seq[1]
				--check if the candidate is in the tail of any sequence
				if isintail(cand, nonemptyseqs) then
					cand = nil --reject candidate
				else
					break
				end
			end

			--add new entry
			if not cand then
				error("Inconsistent hierarchy", 5)
			else
				table.insert(res, cand)
				for _, seq in ipairs(nonemptyseqs) do -- remove cand
					if seq[1] == cand then
						table.remove(seq, 1)
					end
				end
			end
		end
	end

	local function copyTable(t)
		local t2 = {}
		for k, v in pairs(t) do t2[k] = v end
		return t2
	end

	return function(C)
		if C.__mro__ then return copyTable(C.__mro__) end

		-- Compute the class precedence list (mro) according to C3
		local mros = {}
		table.insert(mros, {C})
		for _, base in ipairs(C.__bases__) do
			table.insert(mros, mro(base))
		end
		table.insert(mros, copyTable(C.__bases__))
		return merge(mros)
	end
end)()


function repr_pretty(x, indent, seen, path)
	indent = indent or ""
	path = path or "root"
	seen = seen or {}

	if type(x) == "string" then
		return ("%q"):format(x)
	elseif type(x) == "table" then
		if x.__repr__ then return x:__repr__() end
		if seen[x] then return "#"..seen[x] end
		seen[x] = path
		local str = "{"
		local sep = ""
		local newindent = indent..'\t'
		for k, v in pairs(x) do
			str = str .. sep .. '\n'.. newindent
			local pathk
			if type(k) ~= "string" or not k:match('^[a-zA-Z_][a-zA-Z_0-9]*$') then
				k =  "[" .. repr_pretty(k, newindent, seen) .."]"
				pathk = k
			else
				pathk = '.' .. k
			end
			str = str .. k .. " = ".. repr_pretty(v, newindent, seen, path..pathk)
			sep = ","
		end
		str = str.."\n"..indent.."}"
		seen[x] = str
		return str
	else
		return tostring(x)
	end
end

function prettyprint(...)
	local args = {}
	for _, v in ipairs({...}) do args[_] = repr_pretty(v) end
	print(unpack(args))
end
type_ = {
	__repr__ = function(t)
		return ("<class '%s'>"):format(t.__name__)
	end,
	__init__ = function() end,
	exec = "CRAP"
}
class = setmetatable({}, {
	__call = function(_, name, implementer, baseclasses)
		baseclasses = baseclasses or {}
		local cls = {
			__name__ = name,
			__dict__ = {},
			__bases__ = baseclasses
		}
		cls.__mro__ = mro(cls)
		local instancemt = {}

		--implement method lookups and descriptors (such as properties)
		function instancemt:__index(k)
			local member = cls[k]
			if type(member) == "table" and member.__get__ then
				return member:__get__(self)
			else
				return member
			end
		end
		function instancemt:__newindex(k, v)
			local member = cls[k]
			if member then
				if type(member) == "table" and member.__set__ then
					member:__set__(self, v)
				else
					error("Cannot set static member from non-static context")
				end
			else
				rawset(self, k, v)
			end
		end

		--tostring method
		function instancemt:__tostring(k, v)
			local str = cls.__str__ or cls.__repr__
			if str then
				return str(self)
			else
				return ("<%s instance at 0x%X>"):format(name, self.__id__)
			end
		end

		--Add binary operators
		for _, binop in ipairs({'add', 'sub', 'mul', 'div', 'mod', 'pow'}) do
			local luaname = ("__%s"):format(binop)
			local newname = ("__%s__"):format(binop)
			local rname = ("__r%s__"):format(binop)

			instancemt[luaname] = function(a, b)
				if getmetatable(a) == instancemt then
					if cls[newname] then
						return cls[newname](a, b)
					else
						error()
					end
				elseif getmetatable(b) == instancemt then
					if cls[rname] then
						return cls[rname](b, a)
					else
						error()
					end
				end
			end
		end

		setmetatable(cls, {
			--define the constructor
			__call = function(self, ...)
				local instance = {__class__ = cls}
				instance.__id__ = id(instance)
				setmetatable(instance, instancemt)
				instance:__init__(...)
				return instance
			end,
			--implement inheritance
			__index = function(self, k)
				for _, class in ipairs(self.__mro__) do
					local value = class.__dict__[k]
					if value ~= nil then return value end
				end
				return type_[k]
			end,
			__newindex = __dict__,
			__tostring = type_.__repr__
		})

		--call oldenv in an environment that proxies to the class object 
		local oldenv = getfenv(implementer)
		setfenv(implementer, setmetatable({}, {
			__index = function(_, k)
				local member = cls[k]
				if member ~= nil then
					return member
				else
					return oldenv[k]
				end
			end,
			__newindex = cls.__dict__
		}))(cls)

		return cls
	end,
	--syntactic sugar
	__index = function(self, name)
		return function(_, f, base)
			getfenv()[name] = self(name, f, base)
		end
	end
});

class: property(function()
	function __get__(self, instance)
		if self.getter then return self.getter(instance) else error() end
	end
	function __set__(self, instance, value)
		if self.setter then self.setter(instance, value) else error() end
	end
end)