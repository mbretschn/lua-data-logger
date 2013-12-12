#include <OneWire.h>

// OneWire DS18S20, DS18B20, DS1822 Temperature Logging
//
// Based loosly on the DS18x20_Temperature example from the Arduino IDE 1.0.5.

OneWire ds(9); // on pin 9 (a 4.7K resistor is necessary)

void setup() {
   Serial.begin(9600);
}

// In contrast to the output script, the sensors are not read in the main loop of the program, 
// but depending on a serial event.
void loop() { }

// The main functionality is moved to a function for seperation
void readSensors() {
   ds.reset_search();
   delay(1000);  // wait a second until the complete bus is informed

   boolean complete = false; // helper variable - true if no more sensors found 
   do {
      // some variable declaration
      byte i; byte present = 0; byte type_s; byte data[12]; byte addr[8];

      // variable for calculated temperature and a string which stores the line for later logging
      float celsius; String out = "";
      
      if (!ds.search(addr)) {
         complete = true;   // if no more sensors found, turn complete to true, which stops the loop
      } else {
         // collect the sensor id and put it to out string
         for(i = 0; i < 8; i++) {
            char tmp[16];
            sprintf(tmp, "%02X", addr[i]);
            out += tmp;
         }

         // check the sensor id
         boolean valid = true;
         if (OneWire::crc8(addr, 7) != addr[7]) {
            valid = false;
         } else {
            // the first ROM byte indicates which chip
            switch (addr[0]) {
               case 0x10: //"DS18S20";
                  type_s = 1; break;
               case 0x28: //"DS18B20";
                  type_s = 0; break;
               case 0x22: //"DS1822";
                  type_s = 0; break;
                default: //"NotKnown";
                  valid = false; break;
            } 
  
            // only continue if ckecksum is valid
            if (valid) {
               ds.reset();
               ds.select(addr);
               ds.write(0x44, 1);               // start conversion, with parasite power on at the end
              
               delay(1000);
        
               present = ds.reset();
               ds.select(addr);      
               ds.write(0xBE);                  // Read Scratchpad
               for ( i = 0; i < 9; i++)         // Read 9 bytes
                  data[i] = ds.read();
                          
              // Convert the data to actual temperature
              // because the result is a 16 bit signed integer, it should
              // be stored to an "int16_t" type, which is always 16 bits
              // even when compiled on a 32 bit processor.
               int16_t raw = (data[1] << 8) | data[0];
               if (type_s) {
                  raw = raw << 3;
                  if (data[7] == 0x10)
                     raw = (raw & 0xFFF0) + 12 - data[6];
               } else {
                  byte cfg = (data[4] & 0x60);
                  if (cfg == 0x00) raw = raw & ~7;
                  else if (cfg == 0x20) raw = raw & ~3;
                  else if (cfg == 0x40) raw = raw & ~1;
              }

              // calculate the temperature in celsius 
              // convert it to a string and add it to out variable
              celsius = (double) raw / 16.0;
              char buffer[16];
              dtostrf(celsius, 0, 2, buffer);
              out += buffer;

              // send a line to serial
              Serial.println(out);
            }
         }
      }
   } while (!complete);
}

// main event of programm
// if a reading is identified on the serial port, start readSensors() function
// end the serial communication (so that the other side recognize it) and 
// restart it after a second.
void serialEvent() {
   while (Serial.available()) {
      char inChar = (char) Serial.read();
      readSensors();
      Serial.println("EOD");
      Serial.end();
  }
  delay(1000);
  Serial.begin(9600);
}
