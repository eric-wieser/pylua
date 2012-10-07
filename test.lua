require "main"
require "builtins"

class: Base(function() 
	function __init__(self, num)
		self.num = num
	end
	val = property()
	function val.getter(self)
		return tostring(self.num)
	end
end)

class: Fizz(function() 
	val = property()
	function val.getter(self)
		return self.num % 3 == 0 and "FIZZ" or ""
	end
end, {Base})

class: Buzz(function() 
	val = property()
	function val.getter(self)
		return self.num % 5 == 0 and "BUZZ" or ""
	end
end, {Base})

class: Bazz(function() 
	val = property()
	function val.getter(self)
		return self.num % 7 == 0 and "BAZZ" or ""
	end
end, {Base})

class: FizzBuzz(function()
	val = property()
	function val.getter(self)
		local x = Fizz.val.getter(self)..Buzz.val.getter(self)..Bazz.val.getter(self)
		return x ~= "" and x or Base.val.getter(self)
	end
end, {Fizz, Buzz})


for i in iter(range(3*5*7)) do
	local fb = FizzBuzz(i)
	print(fb.val)
end