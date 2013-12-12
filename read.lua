-- This simple LUA script is used for logging serial port data send by an Arduino to a OpenWRT router

-- add the path where includes could be found
local packages = '/root'
-- adress of the serial port where the arduino is connected
local port = '/dev/tts/1'
-- path where to write logfiles
local path = '/tmp/tempdata'

-- table with 1-wire CRC Lookup values
-- This table comes from Dallas sample code where it is freely reusable,
-- though Copyright (C) 2000 Dallas Semiconductor Corporation
-- http://www.maximintegrated.com/app-notes/index.mvp/id/27
local dscrc_table = {
     0, 94,188,226, 97, 63,221,131,194,156,126, 32,163,253, 31, 65,
   157,195, 33,127,252,162, 64, 30, 95,  1,227,189, 62, 96,130,220,
    35,125,159,193, 66, 28,254,160,225,191, 93,  3,128,222, 60, 98,
   190,224,  2, 92,223,129, 99, 61,124, 34,192,158, 29, 67,161,255,
    70, 24,250,164, 39,121,155,197,132,218, 56,102,229,187, 89,  7,
   219,133,103, 57,186,228,  6, 88, 25, 71,165,251,120, 38,196,154,
   101, 59,217,135,  4, 90,184,230,167,249, 27, 69,198,152,122, 36,
   248,166, 68, 26,153,199, 37,123, 58,100,134,216, 91,  5,231,185,
   140,210, 48,110,237,179, 81, 15, 78, 16,242,172, 47,113,147,205,
    17, 79,173,243,112, 46,204,146,211,141,111, 49,178,236, 14, 80,
   175,241, 19, 77,206,144,114, 44,109, 51,209,143, 12, 82,176,238,
    50,108,142,208, 83, 13,239,177,240,174, 76, 18,145,207, 45,115,
   202,148,118, 40,171,245, 23, 73,  8, 86,180,234,105, 55,213,139,
    87,  9,235,181, 54,104,138,212,149,203, 41,119,244,170, 72, 22,
   233,183, 85, 11,136,214, 52,106, 43,117,151,201, 74, 20,246,168,
   116, 42,200,150, 21, 75,169,247,182,232, 10, 84,215,137,107, 53
}

-- expand package.path
package.path = package.path .. ';' .. packages .. '/?.lua'

-- load bit and hex library
require('bit')
require('hex')

-- check crc8 value for a given rom id
--
-- rom      string  - a string with the rom in hexadecimal form
--
-- returns  boolean - true or false if checksum matches
--
function chk_crc8(rom)
   if not rom or #rom < 16 then
      return false
   end

   local data = {}
   local c = 1
   while c < 16 do
      local part = string.sub(rom, c, c + 1)
      table.insert(data, part)
      c = c + 2
   end

   crc = 0;
   for i = 1, 7, 1 do
      crc = dscrc_table[bit.bxor(crc, hex.to_dec('0x' .. data[i])) + 1]
   end
   return (crc == hex.to_dec('0x' .. data[8]))
end

-- returns a table with current date and time
--
-- returns  table   - in form of { date = <current date 'Y-m-d'>, time = <current time 'H:M:S'> }
--
function datetime()
   local t = os.time()
   return { 
      date = os.date('%Y-%m-%d', t),
      time = os.date('%H:%M:%S', t)
   } 
end

-- appends a line to a file, creates a destination directory based on the 
-- configuration given in the head of this file 
--
-- fname    string  - name of file to write to
-- line     string  - string to write to file
--
function logfile(fname, line)
   os.execute( "mkdir -p " .. path )
   local filename = path .. "/" .. fname
   local f = io.open(filename ,"r")
   if not f then
      os.execute( "touch " .. filename )
        f = io.open (filename, "w")
    else
      io.close(f)
   end
   local f = io.open(filename, "a")
   f:write(line, "\n");
   io.close (f)
end

-- reads sensordata from the serial port (serial port adress configured in head of this file)
-- checks the crc8 checksum of the sensor id and writes the result to a logfile
-- or a message in a error file is any
--
-- returns  table   - with readings. Each value in lines is a table in the form { id = ..., value = ...}
--
function readsensors()
   local wserial=io.open(port,'w')
   wserial:write('1')
   wserial:close()

   local EOD = false
   rserial=io.open(port,'r')
   repeat
      local line=rserial:read('*l')
      if string.sub(line, 0, 3) == "EOD" then
         EOD = true
         rserial:close()
      elseif line then
         local datetime = datetime()
         local data = {
            id  = string.sub(line, 0, 16),
            current_value = tonumber(string.sub(line, 17))
         }
         if chk_crc8(data.id) then
            logfile (datetime.date .. ".dat", datetime.time .. " " .. data.id .. " " .. data.current_value)
         else
            logfile ("glitches.log", datetime.date .. " " .. datetime.time .. " " .. line)
         end
      end
   until EOD == true
end

-- call the readsensor() function and exit
readsensors()
os.exit() 
