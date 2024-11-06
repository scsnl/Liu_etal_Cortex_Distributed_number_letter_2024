"""
serial_test.py

Script for testing the serial port, which is how you 
interact with things like the SRBOx and the scan trigger

"""

import serial
import serial.tools.list_ports
import numpy as np

ports = serial.tools.list_ports.comports()

#list the ports in the output window
for port in ports:
    i = int(port[0][-1]) - 1
    print "Port %i is connected to %s" % (i + 1, port[1])
    #try connecting to port
    ser = serial.Serial(port=i)
    
    #this will trigger the scanner (or turn all srbox lights off)
    ser.write(chr(np.uint8(128+32+64+16)))

    ser.close()

