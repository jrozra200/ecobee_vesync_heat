## GET A PIN FOR YOUR NEW APP

library(httr)

get_pin <- function(client_id) {
    pin <- paste0("https://api.ecobee.com/authorize?response_type=ecobeePin&client",
                  "_id=", client_id, "&scope=smartWrite")
    
    getpin <- GET(pin)
    
    pin_code <- gsub("(^.*ecobeePin\": \")(\\w+)(\".*$)", "\\2", as.character(getpin))
    access_code <- gsub("(^.*code\": \")(\\w+)(\".*$)", "\\2", as.character(getpin))
    
    dat <- data.frame(client_id = client_id,
                      pin_code = pin_code,
                      access_code = access_code)
    
    return(dat)   
}

pin <- get_pin("cS12qzeDY2lWbKC4CNbstHPIsDxFJpgd")

## GET AN ACCESS CODE (AND REFRESH CODE)

get_access_refresh <- function(access_code, client_id){
    get_access_code <- paste0("https://api.ecobee.com/token?grant_type=ecobeePin&code=",
                              access_code, "&client_id=", client_id)
    
    getrefresh <- POST(get_access_code)
    
    at <- gsub("(^.*access_token\": \")(\\w+)(\".*$)", "\\2", as.character(getrefresh))
    rt <- gsub("(^.*refresh_token\": \")(\\w+)(\".*$)", "\\2", as.character(getrefresh))
    
    creds <- data.frame(access_token = at,
                        refresh_token = rt,
                        client_id = client_id)
    
    return(creds)
}

access_refresh <- get_access_refresh(pin$access_code[1], pin$client_id[1])

write.csv(access_refresh, "ecobee.config")
