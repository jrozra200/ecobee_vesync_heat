#!/usr/bin/env Rscript
args = commandArgs(trailingOnly = TRUE)
print(args)

print(paste0(Sys.time(), ": Script Started"))
library(lubridate, quietly = TRUE)
library(httr)
library(jsonlite)
library(dplyr)

print(paste0(Sys.time(), ": Libraries Loaded. Refreshing Ecobee Creds"))

creds <- read.csv("/home/jacobrozran/ecobee/ecobee.config")

refresh <- paste0("https://api.ecobee.com/token?grant_type=refresh_token&code=",
                  creds$refresh_token[1], "&client_id=", creds$client_id[1])

ref <- POST(refresh)

if(grepl("access_token", as.character(ref)) == FALSE) {
    print(paste0(Sys.time(), ": Auth has broken - login and fix it"))
    system(paste0("/bin/bash /home/jacobrozran/ecobee/send_notification.sh >>",
                  " /home/jacobrozran/ecobee/send_notification.log"))
    break
}

at <- gsub("(^.*access_token\": \")((\\w|-|\\.)+)(\".*$)", "\\2", as.character(ref))
rt <- gsub("(^.*refresh_token\": \")((\\w|-|\\.)+)(\".*$)", "\\2", as.character(ref))

creds <- data.frame(access_token = at,
                    refresh_token = rt,
                    client_id = creds$client_id[1])

write.csv(creds, "/home/jacobrozran/ecobee/ecobee.config", row.names = FALSE)

print(paste0(Sys.time(), ": Refreshed Ecobee Creds. Getting temps."))

therm <- paste0("curl -s -H 'Content-Type: text/json' -H 'Authorization: Bearer ",
                creds$access_token[1] , "' 'https://api.ecobee.com/1/thermostat?",
                "format=json&body=\\{\"selection\":\\{\"selectionType\":\"regi",
                "stered\",\"selectionMatch\":\"\",\"includeSensors\":true\\}",
                "\\}' > /home/jacobrozran/ecobee/response.json")

system(therm)

response <- read_json("/home/jacobrozran/ecobee/response.json")

print(paste0(Sys.time(), ": Got Temps. Formatting Data."))

info <- data.frame()
for(sensor in 1:length(response$thermostatList[[1]]$remoteSensors)){
    name <- response$thermostatList[[1]]$remoteSensors[[sensor]]$name
    temp <- as.numeric(response$thermostatList[[1]]$remoteSensors[[sensor]]$capability[[1]]$value) / 10
    occupied <- response$thermostatList[[1]]$remoteSensors[[sensor]]$capability[[2]]$value
    
    tmp <- data.frame(name = name,
                      temp = temp,
                      occupied = occupied)
    tmp$time_utc <- response$thermostatList[[1]]$utcTime
    tmp$time_local <- response$thermostatList[[1]]$thermostatTime
    
    info <- rbind(info, tmp)
}

info$name <- tolower(gsub("'s Room", "", info$name))
info <- info[info$name %in% c("ellie", "office", "regina"), ]

is_it_weekend <- ifelse(weekdays(Sys.Date()) %in% c("Saturday", "Sunday"), TRUE, 
                        FALSE)
print(paste0("Is it a Weekend? ", is_it_weekend))

current_time <- hour(Sys.time()) + (minute(Sys.time()) / 60)
print(paste0("Current Time: ", current_time))

is_afternoon_nap <- FALSE
print(paste0("Is Afternoon Nap? ", is_afternoon_nap))

is_sleeptime <- ifelse(current_time >= 22.25 | current_time <= 10.5, TRUE, FALSE)
print(paste0("Is Kid's Sleep Time? ", is_sleeptime))

is_sleeptime_parents_early <- ifelse(current_time >= 23.0 | current_time <= 1.0, TRUE, FALSE)
print(paste0("Is Parent's Sleep Time (early)? ", is_sleeptime_parents_early))

is_sleeptime_parents_late <- ifelse(current_time > 1.0 & current_time <= 9.5, TRUE, FALSE)
print(paste0("Is Parent's Sleep Time (Late)? ", is_sleeptime_parents_late))

is_sleeptime_parents_wu <- ifelse(((current_time > 9.75 & current_time <= 11) | 
                                       (current_time > 7.75 & current_time <= 8.25)), TRUE, FALSE)
print(paste0("Is Parent's Sleep Time (Wake Up)? ", is_sleeptime_parents_wu))

is_worktime <- ifelse(current_time >= 13, TRUE, FALSE)
print(paste0("Is Work Time? ", is_worktime))

sleep_temp <- 70.0
active_temp <- 72.0
inactive_temp <- 74.0

if (args[1] == "heat") {
    info$action <- case_when(
        (is_sleeptime == TRUE | is_afternoon_nap == TRUE) & 
            info$temp <= sleep_temp & info$name == "ellie" ~ "on", # KIDS ROOM TURNS ON AT NIGHT AND NAP TIME
        info$temp <= inactive_temp & info$name == "ellie" ~ "on", # TOO COLD IN THE KIDS ROOM DURING REGULAR TIME
        ((is_it_weekend == FALSE & is_worktime == TRUE) | info$occupied == "true") & 
            info$temp <= active_temp & info$name == "office" ~ "on", # MY OFFICE TURNS ON DURING THE WEEK OR IF OCCUPIED
        info$temp <= inactive_temp & info$name == "office" ~ "on", # TOO COLD IN THE OFFICE ROOM DURING OTHER TIME
        ((is_sleeptime_parents_early == TRUE | is_sleeptime_parents_wu) & info$temp <= active_temp) & 
            info$name == "regina" ~ "on", # PARENTS BEDROOM HEATING AT NIGHT AND NAP TIME
        (is_sleeptime_parents_late == TRUE & info$temp <= sleep_temp) & 
            info$name == "regina" ~ "on",
        info$temp <= inactive_temp & info$name == "regina" ~ "on", # TOO COLD IN THE MASTER ROOM DURING OTHER TIME
        1 == 1 ~ "off"
    )
} else {
    info$action <- case_when(
        (is_sleeptime == TRUE | is_afternoon_nap == TRUE) & 
            info$temp >= sleep_temp & info$name == "ellie" ~ "on", # KIDS ROOM TURNS ON AT NIGHT AND NAP TIME
        info$temp >= inactive_temp & info$name == "ellie" ~ "on", # TOO HOT IN THE KIDS ROOM DURING REGULAR TIME
        ((is_it_weekend == FALSE & is_worktime == TRUE) | info$occupied == "true") & 
            info$temp >= active_temp & info$name == "office" ~ "on", # MY OFFICE TURNS ON DURING THE WEEK OR IF OCCUPIED
        info$temp >= inactive_temp & info$name == "office" ~ "on", # TOO HOT IN THE OFFICE ROOM DURING OTHER TIME
        ((is_sleeptime_parents_early == TRUE | is_sleeptime_parents_wu) & info$temp >= active_temp) & 
            info$name == "regina" ~ "on", # PARENTS BEDROOM HEATING AT NIGHT AND NAP TIME
        (is_sleeptime_parents_late == TRUE & info$temp >= sleep_temp) & 
            info$name == "regina" ~ "on",
        info$temp >= inactive_temp & info$name == "regina" ~ "on", # TOO HOT IN THE MASTER ROOM DURING OTHER TIME
        1 == 1 ~ "off"
    )
}


print(paste0(Sys.time(), ": Formatted Data. Telling VeSync what to do."))

print(paste0(Sys.time(), ": here is the current status of each room and the state it should be in:"))
print(info)

for(python in 1:dim(info)[1]){
    py_cmd <- paste0("python3 /home/jacobrozran/ecobee/vesync.py ", 
                     info$name[python], " ", info$action[python], 
                     " >> /home/jacobrozran/ecobee/vesync.log 2>&1")
    
    system(py_cmd)
}

print(paste0(Sys.time(), ": Updated the rooms as needed. Script Complete"))
