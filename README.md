pylua
=====

builtins
--------

 * `abs`
 * `any`
 * `all`
 * `callable`
 * `id`
 * `iter`
 * `max`
 * `min`
 * `range`
 * `repr`
 * `property`

classes
-------

Support methods, fields, and properties. Underscore prefix is convention, and as in python, does not force private fields

	class: Timer(function()
		function start(self)
			self._endTime = nil
			self._startTime = tick()
		end
		function stop(self)
			self._endTime = tick()
		end
		pause = stop --alias methods
	 
	 
		function resume(self)
			if self._endTime then
				self._startTime = self._startTime + tick() - self._endTime
				self._endTime = nil
			end
		end
		function clone(self)
			local copy = Timer()
			copy._startTime = self._startTime
			copy._endTime = self._endTime
			return copy
		end
	
		--create a property
		time = property()
		function time.getter(self)
			if self._endTime then
				return self._endTime - self._startTime
			else
				return tick() - self._startTime
			end
		end
	end)

	local t = Timer()
	 
	t:start()
	foo()
	t:stop()
	 
	print(t.time)
	 
	t:resume()
	foo()
	print(t.time)
	t:stop()

Multiple inheritance is also supported:

	class: Rectangle(function()
		function __init__(self, top, left, bottom, right)
			self.top = top
			self.left = left
			self.bottom = bottom
			self.right = right
		end
		function contains(self, x, y)
			return self.top < y and y < self.bottom
			   and self.left < x and x < self.right
		end
	end)

	class: ClickReciever(function()
		function __init__(self)
			self.clickHandlers = []
		end
		function addClickHandler(self, h)
			table.insert(self.clickHandlers, h)
		end
		function fireClick(self, x, y)
			for handler in iter(self.clickHandlers) do
				handler(x, y)
			end
		end
	end)

	class: Button(function()
		function __init__(self, ...)
			Rectangle.__init__(self, ...)
			ClickReciever.__init__(self)
		end
		function fireClick(self, x, y)
			if self:contains(x, y) then
				ClickReciever.fireClick(self, x, y)
			end
		end
	end, {Rectangle, ClickReciever})

Binary arithmetic operators are also supported:

 * `__add__`, `__radd__`
 * `__sub__`, `__rsub__`
 * `__mul__`, `__rmul__`
 * `__div__`, `__rdiv__`
 * `__mod__`, `__rmod__`
 * `__pow__`, `__rpow__`