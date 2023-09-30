library(tidyverse)
library(zipangu)

data <- read_rds('03_middle/2022.11.13_univ_master.rds')

df <-
  data |> 
  mutate(
    list = map(本部所在地, \(x) separate_address(x)),
    都道府県 = map_chr(list, \(x) pluck(x, 'prefecture')),
    市区町村 = map_chr(list, \(x) pluck(x, 'city'))
  ) |>  
  select(大学名, 本部所在地, 都道府県, 市区町村, 設立年, 種別)

write_excel_csv(df, '04_output/univ_master.csv')

