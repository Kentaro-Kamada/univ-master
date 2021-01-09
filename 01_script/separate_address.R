library(tidyverse)
library(zipangu)

data <- read_rds('03_middle/univ_master.rds')

df <- 
  data %>% 
  mutate(
    都道府県 = map_chr(本部所在地, ~{separate_address(.) %>% purrr::pluck('prefecture')}),
    市区町村 = map_chr(本部所在地, ~{separate_address(.) %>% purrr::pluck('city')})
  ) %>% 
  relocate(都道府県:市区町村, .after = 本部所在地)

write_excel_csv(df, '04_output/univ_master.csv')

