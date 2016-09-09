local Actor = class("Actor")

function Actor:ctor( ... )
    logWarn('--- Actor:ctor');
    self.name = "yangx"
    self.age = 123
end

function Actor:func1( ... )
    logWarn(string.format('--- Actor:func1, name:%s, age:%d', self.name, self.age))
end

return Actor

