require 'httpclient'
require 'json'

#input checking
if ARGV.length != 2 || ARGV[0] !~ %r{(boy$)|(girl$)} || ARGV[1] !~ %r{[0-9]{1,}}
  puts "Incorrect number of arguments or bad input"
  puts "USAGE: ruby google_amazon_api_consumption.rb <gender> <max_price>"
  exit
end

#variables
gender = ARGV[0]
max_price = ARGV[1]
google_maps_api_key = "AIzaSyADd3IT4MLQpvFIjfrBtq-UXwwVp51zLKE"

#main routine
google_maps_target_find_url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?inputtype=textquery&fields=opening_hours,formatted_address,geometry&locationbias=ipbias&input=target&key=#{google_maps_api_key}"
httpclient = HTTPClient.new(default_header: {"Content-Type" => "application/json"})
response = httpclient.get(google_maps_target_find_url)
json_response = JSON.parse(response.body)
target_open_bool = json_response["candidates"][0]["opening_hours"]["open_now"]
target_address = json_response["candidates"][0]["formatted_address"]
target_lat = json_response["candidates"][0]["geometry"]["location"]["lat"]
target_lng = json_response["candidates"][0]["geometry"]["location"]["lng"]
target_directions_url = "https://www.google.com/maps/place/#{target_lat},#{target_lng}"

#cant use amazon API unfortunately as you have to pay and have previous sales etc on amazon with tax info
#this logic would work however as I tested it with their sample output from their documentation
amazon_api_associate_id = "someID"
amazon_api_access_key = "key"
amazon_shop_target_api_url = "http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=#{amazon_api_access_key}&associateTag=#{amazon_api_associate_id}&Operation=ItemSearch&Keywords=top%20gifts%20#{gender}&MaximumPrice=#{max_price}"
httpclient = HTTPClient.new(default_header: {"Content-Type" => "application/json"})
response = httpclient.get(amazon_shop_target_api_url)
#error handling as it will return 401 unauthorized
if response.status !~ %r{20[0-4]}
  gift_url = "https://target.com"
else
  json_response = JSON.parse(response.body)
  gift_url = json_response["Item"]["ItemLinks"][0]["ItemLink"]["url"]
end

#output
puts "Target address: #{target_address}"
puts "Open now: #{target_open_bool}"
puts "Link for directions: #{target_directions_url}"
puts "Link for gift: #{gift_url}"
