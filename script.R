link_sheet <- "https://docs.google.com/spreadsheets/d/1o-onWE1_u4QthMlY493-3dIFi2nMDVieZPKNaYFMNYk/"

old <- read.csv("roles.csv")
old$date_closing <- as.Date(old$date_closing)
old$value_salary <- as.numeric(old$value_salary)

# The data is publicly available so we don't need to authenticate
googlesheets4::gs4_deauth()

data_scraped <- googlesheets4::read_sheet(
  ss = link_sheet, 
  skip = 1, 
  col_types = "ccccDcc"
)

colnames(data_scraped) <- c("name_job", "name_firm", "salary_GBP", "name_url", "date_closing", "name_region", "name_contract")

data_scraped$value_salary2 <- gsub(
  "£(\\d+,\\d+).*", "\\1", 
  data_scraped$salary_GBP
  )

data_scraped$value_salary1 <- gsub(
  ".*£(.*)", "\\1", 
  data_scraped$value_salary2
  )

data_scraped$value_salary <- as.numeric(
  gsub(
    ",.*", 
    "", 
    data_scraped$value_salary1
    )
  )

data_scraped$is_partTime <- grepl(
  "part", 
  tolower(data_scraped$name_contract)
  )

data_scraped <- data_scraped[order(rownames(data_scraped)), ]  # To maintain rowwise operations

for (i in 1:nrow(data_scraped)) {
  data_scraped$hash_url[i] <- digest::digest(
    data_scraped$name_url[i], 
    algo = "md5"
    )
}

data_scraped <- data_scraped[, c(colnames(data_scraped)[!colnames(data_scraped) %in% c("value_salary1", "value_salary2")])]

data_new <- subset(
  data_scraped, 
  value_salary > 30 & is_partTime & !(hash_url %in% old$hash_url)
  )

data_log <- data.frame(
  value_date = date(),
  value_rows = nrow(data_new)
  )

write.table(
  x = data_new, 
  file = "roles.csv", 
  sep = ",",
  row.names = FALSE, 
  col.names = FALSE, 
  append = TRUE
  )

write.table(
  x = data_log, 
  sep = ",",
  file = "log.csv", 
  row.names = FALSE, 
  col.names = FALSE, 
  append = TRUE
)
