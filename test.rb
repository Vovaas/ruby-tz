require 'net/http'
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'thread/pool'
require 'csv'

$arr_urls = []
bolean = false

# parse method and add to CSV file
def parse(url)
  html = open(url)
  doc = Nokogiri::HTML(html)
  #take img link
  img_link = ""
  doc.xpath('//*[@id = "view_full_size"]/img').each do |img_block|
    img_link = img_block.attribute('src').text
  end
  #take full name of product
  full = ""
  doc.xpath('//*[@class = "breadcrumb"]/*').each do |full_name|
      full = full_name.search('span.navigation_page').text
  end
  #Parse content of Petsonic in CSV
  CSV.open("d.csv","a", {:col_sep => ";"}) do |wr|
    doc.xpath('//*[@class = "attribute_radio_list"]/*' ).each do |row|
      first_element = doc.at_xpath('//*[@class = "product_main_name"]/*').text + " " + full +  " - " + row.search('span.radio_label').text.strip
      second_element = row.search('span.price_comb').text.strip
      wr << [first_element, second_element, img_link]
    end
  end #end of Parse to CSV
end #end of Parse method

# take count pages of page categories
def takeCountCat(uri)
  i_temp = 0
  while true
    i_temp += 1
    url = URI(uri.chomp('/') + "/?p=" + i_temp.to_s)
    if Net::HTTP.get(url).empty?
      return i_temp - 1
    end #end if
  end #end while
end

#take arr_urls
def getUrls(cat, number)
  html = open(cat.chomp('/') + "/?p=" + number.to_s)
  doc = Nokogiri::HTML(html)
  #Parse links
  doc.xpath('//*[@class = "pro_outer_box"]/*').each do |prod_list|
    prod_list.search('a.product_img_link').each do |each|
      $arr_urls << each.attribute('href').text
    end
    bolean = true
  end #end Parse
end

$category = "https://www.petsonic.com/semihumedos-para-perros/"
pool = Thread.pool(5)

takeCountCat($category).times do |number|
  pool.process do
    getUrls($category, number + 1)
  end
end
pool.shutdown

pool2 = Thread.pool(100)
$arr_urls.each do |url|
  pool2.process do
    parse(url)
  end
end
pool2.shutdown

#if bolean == true
# threads = []
# arr_urls.each do |url|
#   threads << Thread.new do
#     parse(url)
#   end
# end
