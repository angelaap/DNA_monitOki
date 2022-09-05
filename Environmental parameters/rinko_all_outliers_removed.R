
library(dplyr)
library(tibble)
library(readxl)
library(matrixStats)
library(xlsx)
library(purrr)
library(stringr)

# original column names
cols_eng <- c("Date", "Location", "Time", "Depth (m)", "Water temperature (?C)", 
              "Salinity", "Conductivity (mS/cm)", 
              "EC25 (??S/cm)", "Density (kg/m^3)", "??T", 
              "Chl-Flu (ppb)", "Chl-a (??g/l)", "Turbidity range (FTU)",
              "DO (%)", "Weiss-DO (mg/l)", "Voltage (V)", 
              "G&G-DO (mg/l)", "B&K-DO (mg/l)")  

# the desired columns' names
# id: the name of the file the data came from.
vars <- c("id", "date", "location", "sample", "time", 
          "depth", "water_temp", 
          "salinity", "conductivity", 
          "ec25", "density", "sT", 
          "chl_f", "chl_a", "tur_range",
          "do", "weiss_do", "v", 
          "gg_do", "bk_do") 

print(vars[c(2, 5, 6:20)])

# make a separate xls that is ridded of outliers.
# can i get rid of all the variables? 
# what if one variable fits the trend while another doesn't? treat variables individually

# don't want to visualize each variable one by one.
# master table: date(>=9)-location(4)-time(10-15 seconds)-measurement(10)

# write a script to:
# - do a stdev analysis for each variable in each date-location (36)
# - make a new dataframe where outlier values are replaced by NA's

######################################################################################

# this function goes through a column of variable and computes the IQR and the upper-lower bounds for outliers
# when a variable value is out of bounds, it is replaced with NA.
# referred to: https://www.r-bloggers.com/2020/01/how-to-remove-outliers-in-r/
# this is done separately on each excel file that has measurements for a single sample site at a specific date
# so the outliers are removed for each sample-date combination, 
# assuming that a near-uniform measurement is expected for a sample site at a sampling day.
remove_outliers_column <- function (a) {
  b <- as.matrix(a)
  qnt <- colQuantiles(b, probs=c(.25, .75), na.rm = TRUE)
  # print(qnt)
  H <- 1.5 * IQR(b, na.rm = TRUE)
  # print(H)
  low <- qnt[1] - H
  up <- qnt[2] + H
  
  b[a < low] <- NA
  b[a > up] <- NA
  
  b <- as.data.frame(b)
  b 
}

# where all the original raw data excel files are:
rinko_folder <- "C:/Users/Ayse-Oshima/Documents/mitarai_rotation/rinko_raw_data/"

rinko_xls_files <- 
  list.files(path = rinko_folder, recursive = TRUE, pattern = "*.xls")
print(rinko_xls_files)

# loops through all the excel files, applies remove_outliers_column to the columns with variables, (depth, salinity, do, etc)
# which are then bound together, then bound with the sample id columns (date, sample)
# this is then written as an excel file, placed under in a separate folder called: rinko_outliers_removed.
for (xls in rinko_xls_files){
  xls_file <- read_excel(xls, col_names = TRUE)
  # print(nrow(xls_file))
  
  out_removed <- sapply(xls_file[, 3:17], remove_outliers_column) %>%
    bind_cols()
  out_removed_id <- bind_cols(xls_file[1:2], out_removed)
  # print(nrow(out_removed_id))
  colnames(out_removed_id) <- vars[c(2, 5, 6:20)]

  folder <- "C:/Users/Ayse-Oshima/Documents/mitarai_rotation/rinko_outliers_removed/"
  new_name <- paste(folder, xls, sep = "")
  print(new_name)
  
  out_removed_id <- as.data.frame(out_removed_id)
  print(nrow(out_removed_id))
  
  write.xlsx(out_removed_id, new_name, col.names = TRUE, row.names = FALSE)
}

# path to the separate folder that has the outlier-replaced-with-NA excel files
rinko_outliers_removed <- "C:/Users/Ayse-Oshima/Documents/mitarai_rotation/rinko_outliers_removed/"

# list of excel files to loop through and bind together
rinko_xls_no_outliers <- 
  list.files(path = rinko_outliers_removed, recursive = TRUE, pattern = "*.xls")
print(rinko_xls_no_outliers)

readBind <- function (x){
  read_excel(x, col_names = TRUE)
}

# the outlier-replaced-with-NA excel files are all bound together with bind_rows
# to obtain one big excel file with all of the dates and sample combinations
# add vars location and sample depending on the origin file name, which includes these two.
setwd("C:/Users/Ayse-Oshima/Documents/mitarai_rotation/rinko_outliers_removed")
all_outliers_removed <- sapply(rinko_xls_no_outliers, readBind, simplify=FALSE) %>%
  bind_rows(.id = "id") %>% 
  
  mutate(location = substring(str_extract(id, "/..."), 2, 3)) %>%
  relocate(location, .after = date) %>% 
  
  mutate(sample = substring(str_extract(id, "/..."), 2, 4)) %>%
  relocate(sample, .after = location)

# for some reason needs to be a dataframe to write an excel file with row.names = FALSE
write_all_out_removed <- as.data.frame(all_outliers_removed) 
write.xlsx(write_all_out_removed, file = "C:/Users/Ayse-Oshima/Documents/mitarai_rotation/rinko_all_outliers_removed.xls", 
           col.names = TRUE, row.names = FALSE)

View(all_outliers_removed)
nrow(all_outliers_removed)

######################################################################################


