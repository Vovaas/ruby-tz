require 'net/http'
require 'net/https'
require 'curb'
require 'nokogiri'
require 'thread/pool'
require 'csv'

$arr_urls = []

# parse method and add to CSV file
def parse(url,result_file)
  html = Curl.get(url)
  doc = Nokogiri::HTML(html.body_str)
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
  CSV.open(result_file,"a", {:col_sep => ";"}) do |wr|
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
  html = Curl.get(cat.chomp('/') + "/?p=" + number.to_s)
  doc = Nokogiri::HTML(html.body_str)
  #Parse links
  doc.xpath('//*[@class = "pro_outer_box"]/*').each do |prod_list|
    prod_list.search('a.product_img_link').each do |each|
      $arr_urls << each.attribute('href').text
    end
  end #end Parse
end

#take inform from user

puts "Please write file name with out expansion >>"
result_file = gets.chomp() + '.csv'

puts "Please write adress of category >>"
category = gets.chomp()


## develop

#Existence of the file
if(File.exist?(result_file) && !File.empty?(result_file))
  puts 'Start working'
else
  puts 'Start working'
  CSV.open(result_file,"a", {:col_sep => ";"}) do |wr|
    wr << ["name"," price"," image"]
  end
end

#parse link with category page
pool = Thread.pool(10)
countCat = takeCountCat(category)
if countCat != 0 
	countCat.times do |number|
		pool.process do
		  getUrls(category, number + 1)
		end
	end
else
	parse(category, result_file)
	puts "parse link:" + category.to_s
end
pool.shutdown

#parse multipage
pool2 = Thread.pool(50)
$arr_urls.each do |url|
	puts "parse url:" + url.to_s 
  pool2.process do
    parse(url, result_file)
  end
end
pool2.shutdown

puts "End work"
