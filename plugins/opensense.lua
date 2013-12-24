-- Plugin for read.lua
-- send sensor data to opensense
--
-- The plugin must be configured with a opensense API Key and the list of 
-- sensor ids to the corresponding fields.
--
-- The opensense plugin requires luasocket
-- http://luasocket.luaforge.net/
--
local opensense = {
   -- edit opensense API Entpoint is needed
   url = 'http://api.sen.se/events/',
   -- add opensense Write API Key here
   api_key = 'hPPRDU_1T77qRng1BDgJQg',
   feed_ids = {
      '1016D2C000080080' = '48955',
      '10978DB600080006' = '48958'
   }
}

local http  = require("socket.http")
local ltn12 = require("ltn12")

function opensense:send(data, data_path) 
   for i, v in ipairs(data) do
      for k, f in pairs(self.fields) do
         if f == v.id then
            local request_body = '{ "feed_id":' .. k .. ', "value":' .. v.current_value .. "}"

            local header = { 
               ["sense_key"] = self.api_key,
               ["Content-Length"] = #request_body
            }

            local response, b, c, h = http.request{
               url     = self.url,
               headers = header,
               method  = "POST",
               source  = ltn12.source.string(request_body)
            }

            if response ~= 1 then
               local datetime = datetime()
               logfile ("opensense_http.log", datetime.date .. " " .. datetime.time .. " opensense: " .. h, data_path)
            end
         end
      end   
   end
end

return opensense