# What is this?

Taking previous integrations further, I am using this script to heat my office 
and kids' room. 

To solve this, I am getting my temperature from the ecobee API, checking to see 
if it is too hot/cold, then taking appropriate action with my VeSync outlets.

# My Equipment

I have an [Ecobee 3 lite](https://www.ecobee.com/ecobee3-lite/) with two 
[Smart Sensors](https://www.ecobee.com/en-us/smart-sensor/). I am also using 
[Etekcity Voltson Smart WiFi Outlets](http://www.vesync.com/esw01usa). 

That's the "smart" bit. To heat the room, I am just using your run-of-the-mill 
floor heater I got at Home Depot or something... 

# Getting Started

To start, you need to 
[create an app and authenticate with Ecobee](https://github.com/jrozra200/ecobee_vesync_connect/blob/master/initiating_ecobee_login.md).

VeSync is a bit easier to authenticate. Download the [app](https://itunes.apple.com/us/app/vesync/id1289575311?mt=8) 
and create a login. You'll use that login for the 
[script](https://github.com/jrozra200/ecobee_vesync_connect/blob/master/vesync.py).

## Server

This time around, I am using the google could instead of AWS. Either I messed up 
my AWS account or they did... either way, it says I need to pay before I can 
create a new instance, but there is no outstanding charges. The path of least 
resistance for me was to go to another cloud provide. I think it will be like $5 
a month to run a small instance in the google cloud. Whatever.

### Server Requirements

You don't have to install much on the server - just R, the python pip installer, 
and open ssl. 

```
sudo apt-get install r-base
sudo apt-get install python3-pip
sudo apt-get install libssl-dev libcurl4-openssl-dev
sudo apt-get install sendmail mailutils sendmail-bin
```

### R Requirements

You'll just need a few packages installed to run the R bit:

1. lubridate
2. httr
3. jsonlite

You can run this line of code in `sudo R` (as root): 

```
install.packages(c("lubridate", "httr", "jsonlite", "dplyr"))
```

### Python Requirements

There are 4 packages called, but 2 should be installed with your system already. 

1. datetime
2. sys

The other 2, you'll need to install:

1. pandas
2. pyvesync

You can do that with this code:

```
sudo pip3 install pandas
sudo pip3 install pyvesync
```

### Mail Relay Requirements (for notifications)

Go [here](https://linuxconfig.org/configuring-gmail-as-sendmail-email-relay) and 
follow the steps. 
