import selenium
import datetime
import time
# 本日の日付
date = str(datetime.date.today()).replace('-', '.')


# chromeの起動
driver = selenium.webdriver.Chrome()

###### 国公立大学の取得
# 大学ポートレートのサイトを起動
driver.get('https://portraits.niad.ac.jp/index.html')
time.sleep(3)

# 設置形態の「国立」と「公立」をクリック
driver.find_element(by = 'id', value = 'national').click()
time.sleep(2)
driver.find_element(by = 'id', value = 'public').click()
time.sleep(2)

# 検索ボタンクリック
driver.find_element(by = 'css selector', value = '.search_btn').click()
# 長めに待機
time.sleep(7)

# htmlを取得＆保存
html = driver.page_source
with open('02_input/' + date + '_univ_list_national.html', 'w', encoding = 'utf-8') as f:
  f.write(html)



###### 私立大学の取得
# 大学ポートレートのサイトを起動
driver.get('https://portraits.niad.ac.jp/index.html')
time.sleep(3)

# 設置形態の「私立」をクリック
driver.find_element(by = 'id', value = 'private').click()
time.sleep(2)

# 検索ボタンクリック
driver.find_element(by = 'css selector', value = '.search_btn').click()
# 長めに待機
time.sleep(7)

# htmlを取得＆保存
html = driver.page_source
with open('02_input/' + date + '_univ_list_private.html', 'w', encoding = 'utf-8') as f:
  f.write(html)



# ページを閉じる
driver.close()
