library(tidyverse)
library(rvest)


# 一覧の取得 ---------------------------------------------------------------------------------------
# 国公立
univ_list_national <- read_html('02_input/2020.12.08_univ list national.html')

tibble(
  大学名 = 
    univ_list_national %>% 
    html_nodes('div.name_daigaku a') %>% 
    html_text(),
  url = 
    univ_list_national %>% 
    html_nodes('div.name_daigaku a') %>% 
    html_attr('href')
) %>% 
  write_rds(file = '03_middle/univ url list national.rds')

# 私立
univ_list_private <- read_html('02_input/2020.12.08_univ list private.html')

tibble(
  大学名 = 
    univ_list_private %>% 
    html_nodes('div.name_daigaku a') %>% 
    html_text(),
  url = 
    univ_list_private %>% 
    html_nodes('div.name_daigaku a') %>% 
    html_attr('href')
) %>% 
  write_rds(file = '03_middle/univ url list private.rds')

rm(list = ls())

# それぞれのページから情報をとる----------------------------------------------------------------------------------

# 国公立 -----------------------------------------------------------------------------------------

url_list_national <- read_rds('03_middle/univ url list national.rds')

scrape_result <- 
  url_list_national %>% 
  mutate(bow = map(url, ~{polite::bow(url = ., user_agent = 'Sickle-sword', delay = 3)})) %>% 
  mutate(scrape_result = map(bow,
                             ~{polite::scrape(.x, content = list(charset = 'utf-8'))}
  ))

univ_master_national <- 
  scrape_result %>% 
  mutate(data = map(scrape_result, 
                    ~{tibble(
                      name = 
                        html_nodes(., '.basic_info dt') %>% 
                        html_text(),
                      value = 
                        html_nodes(., '.basic_info dd') %>% 
                        html_text()
                    ) 
                    })) %>% 
  select(大学名, data) %>% 
  unnest(data) %>% 
  filter(name != '大学名') %>% 
  pivot_wider(id_cols = 大学名) %>% 
  select(大学名, 本部所在地, 設立年 = `設立年（設置認可年）`, 種別 = 大学の種類) %>% 
  mutate(
    本部所在地 = str_remove_all(本部所在地, '\\n') %>% stringi::stri_trans_nfkc(),
    設立年 = parse_double(設立年),
    種別 = str_remove(種別, '（.+）')
  ) 

write_rds(univ_master_national, '03_middle/univ_master_national.rds')


# 私立 ------------------------------------------------------------------------------------------


url_list_private <- read_rds('03_middle/univ url list private.rds')

scrape_result <-
  url_list_private %>% 
  mutate(url = str_replace(url, 'category01', 'category08')) %>% 
  mutate(bow = map(url, ~{polite::bow(url = ., user_agent = 'Sickle-sword', delay = 3)})) %>% 
  mutate(scrape_result = map_chr(bow, 
                                 ~{polite::scrape(., content = list(charset = 'euc-jp')) %>%
                                     str_conv('euc-jp')
                                 }
  ))

univ_master_private <-
  scrape_result %>% 
  mutate(
    本部所在地 = 
      str_extract(scrape_result,
                  '(?<=td class="univ_content04"><span itemprop="description">).+(?=</span></td>)') %>% 
      stringi::stri_trans_nfkc(),
    設立年 = 
      str_extract(scrape_result,
                  '(?<=<td class="univ_content03" colspan="2"><span itemprop="foundingDate">).+(?=</span></td>)')
  ) %>% 
  select(大学名, 本部所在地, 設立年) %>% 
  mutate(
    設立年 = zipangu::convert_jyear(設立年),
    種別 = case_when(str_detect(大学名, '短期大学') ~ '私立・短期大学', TRUE ~ '私立・大学')
  )
  
write_rds(univ_master_private, '03_middle/univ_master_private.rds')


# データ合併 ---------------------------------------------------------------------------------------

univ_master_national <- read_rds('03_middle/univ_master_national.rds')
univ_master_private <- read_rds('03_middle/univ_master_private.rds')

univ_master <- 
  bind_rows(
    univ_master_national,
    univ_master_private 
  )

write_rds(univ_master, '03_middle/univ_master.rds')
