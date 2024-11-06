#test_keyboard.py

from psychopy.iohub import launchHubServer

io = launchHubServer()
kb = io.devices.keyboard
kb.enableEventReporting(True)


quit = False

print dir(kb)

#while not quit:
#    key = kb.getEvents()
#    if key:
#            if key[0].key=='q' or key[0].key=='escape':
#                exit()
#            else:
#                print key[0].key