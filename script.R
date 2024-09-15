link_sheet <- "https://docs.google.com/spreadsheets/d/1o-onWE1_u4QthMlY493-3dIFi2nMDVieZPKNaYFMNYk/"

old <- readr::read_csv(
  file = "roles.csv", 
  col_types = "ccccDccdl", 
  col_names = TRUE
  )

# The data is publicly available so we don't need to authenticate
googlesheets4::gs4_deauth()

data_new <- googlesheets4::read_sheet(
  ss = link_sheet, 
  skip = 1, 
  col_types = "ccccDcc"
  ) |> 
  dplyr::select(
    "name_job" = Job, "name_firm" = Organisation, `Salary (GBP)`, 
    "name_url" = URL, `Closing Date`, name_region = Region, 
    "name_contract" = `Contract/Hours`
    ) |> 
  dplyr::mutate(
    value_salary2 = stringr::str_extract(`Salary (GBP)`, "£\\d+,\\d+"),
    value_salary1 = stringr::str_extract(value_salary2, "(?<=£).*"),
    value_salary = as.numeric(stringr::str_remove(value_salary1, ",")),
    is_partTime = stringr::str_detect(stringr::str_to_lower(name_contract), "part"),
  ) |> 
  dplyr::rowwise() |> 
  dplyr::mutate(hash_url = rlang::hash(name_url)) |> 
  dplyr::select(-value_salary1, -value_salary2) |> 
  dplyr::filter(
    value_salary > 30000,
    is_partTime,
    !(name_url %in% old$name_url)
    )

readr::write_csv(
  x = data_new, 
  file = "roles.csv", 
  col_names = FALSE,
  append = TRUE
  )
