library(tidyverse)
library(rvest)

date <- Sys.Date() |> str_replace_all('-', '.')

# 一覧の取得 ---------------------------------------------------------------------------------------
# htmlの取得→pythonのseleniumで取得

# 国公立
univ_list_national <- read_html(str_c('02_input/', date, '_univ_list_national.html'))


tibble(
  大学名 = 
    univ_list_national |> 
    html_nodes('div.name_daigaku a') |> 
    html_text(),
  url = 
    univ_list_national |> 
    html_nodes('div.name_daigaku a') |> 
    html_attr('href')
) |> 
  write_rds(file = str_c('03_middle/', date, '_univ_url_national.rds'))

# 私立
univ_list_private <- read_html(str_c('02_input/', date, '_univ_list_private.html'))

tibble(
  大学名 = 
    univ_list_private |> 
    html_nodes('div.name_daigaku a') |> 
    html_text(),
  url = 
    univ_list_private |> 
    html_nodes('div.name_daigaku a') |> 
    html_attr('href')
) |> 
  write_rds(file = str_c('03_middle/', date, '_univ_url_private.rds'))


# それぞれのページから情報をとる----------------------------------------------------------------------------------

# 国公立 -----------------------------------------------------------------------------------------

# urlリスト読み込み
url_list_national <- read_rds(str_c('03_middle/', date, '_univ_url_national.rds'))



# 各大学ページのhtml取得
scrape_result_national <-
  url_list_national |> 
  mutate(scrape_result = map(url, .progress = TRUE, \(x) {
    Sys.sleep(3)
    read_html(x)
  }))


# 欲しい要素を抜き出す
univ_master_national <-
  scrape_result_national |> 
  mutate(
    data = 
      map(
        scrape_result, \(x) {
          tibble(
            name = 
              html_nodes(x, '.basic_info dt') |> 
              html_text(),
            value = 
              html_nodes(x, '.basic_info dd') |> 
              html_text()
          )
        }
      )
  ) |> 
  # 形を整える
  select(大学名, data) |> 
  unnest(data) |> 
  filter(name != '大学名') |> 
  pivot_wider(id_cols = 大学名) |>
  select(大学名, 本部所在地, 設立年 = `設立年（設置認可年）`, 種別 = 大学の種類) |>
  mutate(
    本部所在地 = str_remove_all(本部所在地, '\\n') |> stringi::stri_trans_nfkc(),
    設立年 = parse_double(設立年),
    種別 = str_remove(種別, '（.+）')
  ) 

write_rds(univ_master_national, str_c('03_middle/', date, '_univ_master_national.rds'))


# 私立 ------------------------------------------------------------------------------------------

url_list_private <- read_rds(str_c('03_middle/', date, '_univ_url_private.rds'))


scrape_result_private <-
  url_list_private |> 
  # category01は「本学の特色」で目的のサイトはcategory08の「基本情報」
  # 参考：https://up-j.shigaku.go.jp/school/category08/00000000271201000.html
  mutate(url = str_replace(url, 'category01', 'category08')) |> 
  # 各大学ページのhtml取得
  # 文字コードに注意
  mutate(scrape_result = map(url, .progress = TRUE, \(x) {
    Sys.sleep(3)
    # 一旦生のまま読んで
    read_file(x) |> 
      # エンコーディングを変換
      str_conv('euc-jp') |> 
      # htmlとして読み直す
      read_html()
  }))


univ_master_private <-
  scrape_result_private |> 
  mutate(
    本部所在地 = 
      map_chr(scrape_result, \(x) html_element(x, 'span[itemprop=description]') |> html_text()) |> 
      stringi::stri_trans_nfkc(),
    設立年 = 
      map_chr(scrape_result, \(x) html_element(x, 'span[itemprop=foundingDate]') |> html_text()) |> 
      stringi::stri_trans_nfkc()
  ) |> 
  select(大学名, 本部所在地, 設立年) |> 
  mutate(
    設立年 = zipangu::convert_jyear(設立年),
    種別 = case_when(str_detect(大学名, '短期大学') ~ '私立・短期大学', .default = '私立・大学')
  )
  
write_rds(univ_master_private, str_c('03_middle/', date, '_univ_master_private.rds'))


# データ合併 ---------------------------------------------------------------------------------------

univ_master_national <- read_rds(str_c('03_middle/', date, '_univ_master_national.rds'))
univ_master_private <- read_rds(str_c('03_middle/', date, '_univ_master_private.rds'))

univ_master <- 
  bind_rows(
    univ_master_national,
    univ_master_private 
  )

write_rds(univ_master, str_c('03_middle/', date, '_univ_master.rds'))
