lua-data-logger
===============

This simple LUA script is used for logging serial port data send by an Arduino to a OpenWRT router

The Project contains a Arduino Sketch (temperature.ino) within the folder temperature which bases loosly on the DS18x20_Temperature example from the Arduino IDE 1.0.5.

### Arduino Sketch
The Arduino programm sends the Sensor ID and the calculated temperature in celsius in a line via the serial port of the Atmega chip for all found sensors once an entry has been registered via the serial port.

### LUA
The LUA script is designed to receive this serial data and write it to a logfile and could be used as a cron job and it is tested on a OpenWRT backfire installation on a Linksys WRT54 router. 

In order to ensure that only valid data is stored, the checksum of the sensor ID is calculated and compared with the data for receiving. The calculation of the sensor ID requires bitwise operations and conversion of hexadecimal to binary numbers. This is done with parts of the luabitv0.4 library (http://files.luaforge.net/releases/bit/bit/luabitv0.4)

### Configuration
The LUA script read.lua cound be configured respecting the Serial Port Adress and the path, where the Logfiles are stored:

`local port = '/dev/tts/1'`

`local path = '/tmp/tempdata'`

This configuration options are found on the top of the read.lua file.

### Logging
If the logging is started, a file based on the current date is created in the destination path and holds a line for each sensor started with the time of the mesurement, the Sensor ID and the mesured temperature in celsius. If a glitch is identified, a log message is stored in a specific file 'glitch.log' in the same directory.

See: <http://mb.aquarius.uberspace.de/use-lua-for-serial-data-logging> for more details.