
# Load libraries ----------------------------------------------------------

library(rvest)
library(dplyr)



# Extract -----------------------------------------------------------------

# read the page
page <- read_html("https://metro.co.uk/rush-hour-crush/?ico=rhc_banner_home/home")

# extract text and author
text <- html_text(html_elements(page, ".metro-rush-hour-crush p"))
author <- html_text(html_elements(page, ".metro-rush-hour-crush h4"))

# bind it to dataframe
df <- data.frame(text = text, author = author)

# add date of collection
df$date <- Sys.time()



# Combine -----------------------------------------------------------------

path <- "D:/Nextcloud/_clanky/UCL_Rush_hour_crush/"

# load old dataframe
df_old <- readRDS(paste0(path, "RHC_dataframe"))


# find what's new
new <- df %>%
       group_by(author, text) %>%
         subset(!(text%in%df_old$text))

# Determine what to do next
if(nrow(new) == 8) {
  # if there is 8 new posts (max on page), load dynamic scraping script -> 
  # Selenium script allows getting also posts from next pages
  source(paste0(path, "3_scrape_new_Selenium.R"))
} else {
  # bind new observations to old dataset & save
  df_updated <- rbind(new, df_old)
  saveRDS(df_updated, paste0(path, "RHC_dataframe"))
  write.csv(df_updated, paste0(path, "RHC_dataframe.csv"), row.names = F)
}

