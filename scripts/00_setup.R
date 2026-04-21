pkgs <- c("tidyverse", "readxl", "countrycode", "here")
new <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new)) install.packages(new)
lapply(pkgs, library, character.only = TRUE)
