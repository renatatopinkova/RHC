
# Load libraries ----------------------------------------------------------

library(RSelenium)
library(wdman)
library(rvest)
library(plyr)
library(tidyr)

# Set up driver -----------------------------------------------------------

# set up port - must be an integer, otherwise throws an error in wdman::selenium() command
PORT <- as.integer(4444)

# set up server
server <- wdman::selenium(port = PORT) # note: could be started with selenium() w/o port, but better to specify it

# set up the browser
# firefox - recommended, crashes the least
browser <- remoteDriver(
  browserName = "firefox",
  port = PORT
)

class(browser)


# Open browser ------------------------------------------------------------

browser$open()

# navigate to the Rush hour crush 
browser$navigate("https://metro.co.uk/rush-hour-crush/?ico=rhc_banner_home/home")


# Get to the bottom -----------------------------------------------------

## possbile way forward - get to the end of the page by load more 
## & then scrape all & assign it numbers

# locate "load more" button
load_more <- browser$findElement('id', "metro-rush-hour-crush-load-more")

# get to the bottom of the site (click until the button disappears)
i <- 1
while (TRUE) {
  load_more$clickElement()
  print(paste("Finished iteration n.", i))
  Sys.sleep(runif(1, 1, 4))
  i <- i + 1
} 
# if the button is not there, it will still attempt it and not fail!! Break manually


# Extract everything ------------------------------------------------------


container <- browser$findElements("class", "metro-rush-hour-crush")
length(container) # 353 posts


# getting text - toy example
container[[1]]$findElement("tag", 'p')$getElementText()
container[[2]]$findElement("tag", 'p')$getElementText()

# getting the author - toy example
container[[1]]$findElement("tag", 'h4')$getElementText()

# gets both in one go - can be splitted later in text - author by \n
content <- sapply(container, function(x) x$getElementText())


# Binding it to a dataframe -----------------------------------------------

# bind it to a dataframe
df <- plyr::ldply(content, data.frame)
names(df)[1] <- "text"

# detach plyr so it doesn't clash with dplyr
detach("package:plyr", unload=TRUE)

# split stringr to text & author columns
split <- tidyr::separate(df, col = text, 
                  sep = "\\n", into = c("text", "author"))

write.csv(split, "RHC_dataframe.csv")



# stop server after session
server$stop()
