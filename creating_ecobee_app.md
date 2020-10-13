# 1. Become an Ecobee Developer

Go to [Ecobee's developer's website](www.ecobee.com/developers) and select 
["BECOME A DEVELOPER"](https://www.ecobee.com/home/developer/loginDeveloper.jsp). 

# 2. Create an Ecobee App

Once you have filled out the request information, login at the main 
[Ecobee website](www.ecobee.com). 

From the main dashboard, click the main menu (top right) and select the 
**Developer** option. 

On this screen, select "Create New" and fill out (at a minimum):

1. Application Name
2. Application Summary
3. Authorization Method (choose ecobee PIN) 

Click "Create"

# 3. Request a PIN for your new App

I've created 
[this script](https://github.com/jrozra200/ecobee_vesync_connect/blob/master/ecobee_config_restore_functions.R) 
that takes your client id and gets a pin.

Here's the function and code to get your pin. Just put your client id into the 
part below that says **"YOUR CODE HERE"**

```
## GET A PIN FOR YOUR NEW APP

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

pin <- get_pin("YOUR CODE HERE")
```

# 4. Approve your Apps Access

Back at the Ecobee site, go to **My Apps** from the main menu (still top right). 
On this page, click **Add Application** and copy the pin you got from the last 
step. 

Your pin can be found by running `pin$pin_code[1]` (from last step).

# 5. Get a Refresh Code

Once you've granted access, you can use the access code you received to get a 
refresh code (which you'll need after the first authentication).

```
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
```

I highly recommend saving the details you got in this step for the next run. 