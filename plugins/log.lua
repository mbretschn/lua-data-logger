-- Plugin for read.lua
-- writes data to a log file

local logger = { }

function logger:send(data, data_path) 
   for i, v in ipairs(data) do
      logfile (v.datetime.date .. ".dat", v.datetime.time .. " " .. v.id .. " " .. v.current_value, data_path)
   end
end

return logger