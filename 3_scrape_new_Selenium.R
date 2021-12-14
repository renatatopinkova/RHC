
# Load libraries ----------------------------------------------------------

library(RSelenium)
library(wdman)
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


# Get first three pages -----------------------------------------------------

# wait for page to load
Sys.sleep(10)

# confirm cookies (otherwise scrolling is disabled)
cookie <- browser$findElement("class", "level1PrimaryButton-0-0-8")
cookie$clickElement()


# locate "load more" button
load_more <- browser$findElement('id', "metro-rush-hour-crush-load-more")

# go three pages deep (should not be more than 2 new pages, but let's be cautious)
i <- 1
while (TRUE) {
  # go down to see the button (getElementLocationInView does not work properly)
  browser$executeScript(paste0("window.scrollTo(0, ", i*1800, ");"))
  Sys.sleep(runif(1,1,2))
  # click on button
  load_more$clickElement()
  Sys.sleep(runif(1, 1, 4))
  i <- i + 1
  print(paste("Finished iteration n.", i))
  if(i == 3) {
    break
  }
} 
# Extract everything ------------------------------------------------------


container <- browser$findElements("class", "metro-rush-hour-crush")
length(container) 


# Get text from container
content <- sapply(container, function(x) x$getElementText())

# stop server after session
server$stop()



# Binding it to a dataframe -----------------------------------------------

# bind text to a dataframe
df <- plyr::ldply(content, data.frame)
names(df)[1] <- "text"

# detach plyr so it doesn't clash with dplyr later
detach("package:plyr", unload=TRUE)

# split strings to text & author columns by newline
df <- tidyr::separate(df, col = text, 
                         sep = "\\n", into = c("text", "author"))


# add date of collection
df$date <- Sys.time()

# Combine -----------------------------------------------------------------

# load dplyr
library(dplyr)

path <- "D:/Nextcloud/_clanky/UCL_Rush_hour_crush/"

# load old dataframe
df_old <- readRDS(paste0(path, "RHC_dataframe"))


# find what's new
new <- df %>%
  group_by(author, text) %>%
  subset(!(text%in%df_old$text))

# bind it to the old dataset
df_updated <- rbind(new, df_old)

# save
saveRDS(df_updated, paste0(path, "RHC_dataframe"))
write.csv(df_updated, paste0(path, "RHC_dataframe.csv"), row.names = F)
