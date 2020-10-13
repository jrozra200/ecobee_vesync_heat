import datetime
from pyvesync import VeSync
import pandas as pd
import sys

print(str(datetime.datetime.now()) + ": Libraries loaded & script starting.")

config = pd.read_csv("/home/jacobrozran/ecobee/vesync.config")

manager = VeSync(config.email[0], config.password[0])
manager.login()
manager.update()

print(str(datetime.datetime.now()) + ": Connected to VeSync. Figuring out what to do for " + sys.argv[1])

for out in range(len(manager.outlets)):
    if sys.argv[1] in str.lower(str(manager.outlets[out])):
        name = out
        
switch = manager.outlets[name]

if 'status: on' in str.lower(str(switch)):
    status = 'on'
else:
    status = 'off'

print(str(datetime.datetime.now()) + ": " + sys.argv[1] + " outlet is " + status + " and needs to be " + sys.argv[2])

if (sys.argv[2] == 'on' and status == 'off'):
    switch.turn_on()
    response = "turned on switch"
elif (sys.argv[2] == 'off' and status == 'on'):
    switch.turn_off()
    response = "turned off switch"
else:
    response = "did nothing"

print(str(datetime.datetime.now()) + ": " + response + " and now script is complete.")

