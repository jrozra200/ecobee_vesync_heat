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
for(sensor in 1:3){
    name <- response$thermostatList[[1]]$remoteSensors[[sensor]]$name
    temp <- as.numeric(response$thermostatList[[1]]$remoteSensors[[sensor]]$capability[[1]]$value) / 10
    
    tmp <- data.frame(name = name,
                      temp = temp)
    tmp$time_utc <- response$thermostatList[[1]]$utcTime
    tmp$time_local <- response$thermostatList[[1]]$thermostatTime
    
    info <- rbind(info, tmp)
}

info$name <- tolower(gsub("'s Room", "", info$name))
info <- info[info$name %in% c("ellie", "office", "regina"), ]

is_it_weekend <- ifelse(weekdays(Sys.Date()) %in% c("Saturday", "Sunday"), TRUE, 
                        FALSE)
current_time <- hour(Sys.time()) + (minute(Sys.time()) / 60)
is_afternoon_nap <- ifelse(current_time >= 16 & current_time <= 19.5, TRUE, FALSE)
is_sleeptime <- ifelse(current_time >= 23 | current_time <= 11, TRUE, FALSE)
is_sleeptime_parents <- ifelse(current_time >= 1 & current_time <= 11, TRUE, FALSE)
is_worktime <- ifelse(current_time >= 13, TRUE, FALSE)

info$action <- case_when(
    (is_sleeptime == TRUE | (is_it_weekend == TRUE & is_afternoon_nap == TRUE)) & 
        info$temp <= 70 & info$name == "ellie" ~ "on", # KIDS ROOM TURNS ON AT NIGHT AND NAP TIME
    is_it_weekend == FALSE & is_worktime == TRUE & info$temp <= 72 & 
        info$name == "office" ~ "on", # MY OFFICE TURNS ON DURING THE WEEK
    is_sleeptime_parents == TRUE & info$temp <= 70 & 
        info$name == "regina" ~ "on", # PARENTS BEDROOM HEATING
    1 == 1 ~ "off"
)

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
