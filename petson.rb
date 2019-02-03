require 'open-uri'
require 'nokogiri'
require 'csv'

#start Parse method
def parse(directory)
begin
  html = open(directory)
  doc = Nokogiri::HTML(html)
rescue
  puts "Try again is error link - " + $category.to_s
end
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
  CSV.open($result_file,"a", {:col_sep => ";"}) do |wr|
    doc.xpath('//*[@class = "attribute_radio_list"]/*' ).each do |row|
      first_element = doc.at_xpath('//*[@class = "product_main_name"]/*').text + " " + full +  " - " + row.search('span.radio_label').text.strip
      second_element = row.search('span.price_comb').text.strip
      wr << [first_element, second_element, img_link]
    end
  end #end of Parse to CSV
end #end of Parse method

# Get file with resoult
puts "Please write file name with out expansion >>"
$result_file = gets.chomp() + '.csv'
# Get link
puts "Please write adress of category >>"
$category = gets.chomp()


#Existence of the file
if(File.exist?($result_file) && !File.empty?($result_file))
  puts 'Start working'
else
  puts 'Start working'
  CSV.open($result_file,"a", {:col_sep => ";"}) do |wr|
    wr << ["name"," price"," image"]
  end
end

# mass of needed urls for parse with page categore
arr_urls = []
bolean = false


begin
  html = open($category)
  doc = Nokogiri::HTML(html)

#Parse
  doc.xpath('//*[@class = "pro_outer_box"]/*').each do |prod_list|
    prod_list.search('a.product_img_link').each do |each|
      arr_urls << each.attribute('href').text
    end
    bolean = true
  end #end Parse
rescue
  puts "Try again is error link - " + $category.to_s
end

# Parse multipage
i=0
if bolean == true
  while i < arr_urls.length
    i+=1
    parse(arr_urls[i-1])
    puts i.to_s + ":pages is added"
  end #end of while
else
  parse($category)
  puts "page is added"
end #end if
puts "work is done"
