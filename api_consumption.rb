require 'httpclient'
require 'json'
require 'nokogiri'
require 'xml/to/hash'

#input checking
if ARGV.length != 3 || ARGV[2] !~ %r{north$|south$|west$|east$}
  puts "Incorrect number of arguments or bad input"
  puts "USAGE: ruby api_consumption.rb <bus_route> <bus_stop> <bus_direction>"
  exit
end

#variables
bus_route = ARGV[0]
bus_stop = ARGV[1]
bus_direction = ARGV[2]
bus_routeID = ""
bus_stop_exists = false
bus_stopID = ""
closest_bus_times = Array.new
case bus_direction
when "south"
  bus_direction = "1"
when "north"
  bus_direction = "4"
when "east"
  bus_direction = "2"
when "west"
  bus_direction = "3"
end

#get routeID
mn_transit_routes_url = "https://svc.metrotransit.org/NexTrip/Routes"
httpclient = HTTPClient.new
response = httpclient.get(mn_transit_routes_url)
response_xml = Nokogiri::XML(response.body)
response_xml.css("ArrayOfNexTripRoute").each do |next_trip_route|
  next_trip_route.css("NexTripRoute").each do |route|
    route.children.each do |child|
      if child.to_s =~ %r{^.Description.#{bus_route}}
        bus_routeID = child.next_sibling.next_sibling.text
      end
    end
  end
end
if bus_routeID == ""
  puts "Please enter a valid bus route"
  exit
end

#check to make sure stop is on the bus route in that direction
mn_transit_stops_url = "https://svc.metrotransit.org/NexTrip/Stops/#{bus_routeID}/#{bus_direction}"
httpclient = HTTPClient.new
response = httpclient.get(mn_transit_stops_url)
response_xml = Nokogiri::XML(response.body)
if response_xml.css("ArrayOfTextValuePair/TextValuePair").length == 0
  puts "Please enter a valid direction for the bus_route"
  exit
end
response_xml.css("ArrayOfTextValuePair").each do |next_trip_route|
  next_trip_route.css("TextValuePair").each do |route|
    route.children.each do |child|
      if child.to_s =~ %r{^.Text.#{bus_stop}}
        bus_stop_exists = true
        bus_stopID = child.next_sibling.text
      end
    end
  end
end
if bus_stop_exists == false
  puts "Please enter a valid bus stop for the bus route and direction"
  exit
end

#find closest bus
mn_transit_location_url = "https://svc.metrotransit.org/NexTrip/#{bus_routeID}/#{bus_direction}/#{bus_stopID}"
httpclient = HTTPClient.new
response = httpclient.get(mn_transit_location_url)
response_xml = Nokogiri::XML(response.body)
if response_xml.css("ArrayOfNexTripDeparture/NexTripDeparture").length == 0
  puts "There are no more buses"
  exit
end
response_xml.css("ArrayOfNexTripDeparture").each do |next_trip_route|
  next_trip_route.css("NexTripDeparture").each do |route|
    route.children.each do |child|
      if child.to_s =~ %r{^.DepartureTime}
        closest_bus_times.push(child.text)
      end
    end
  end
end

#times of the buses arrival is in the form of 2019-12-03T17:54:39
number_of_buses = closest_bus_times.size
decomissioned_buses = 0
closest_bus_times.each do |time|
  decomissioned_buses += 1 if time !~ %r{[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]}
end
if decomissioned_buses == number_of_buses
  puts "There are no more buses"
  exit
end
closest_bus = closest_bus_times.sort[0]

#calculate waiting time for bus
current_time_hours = Time.now.hour
current_time_mins = Time.now.min
closest_bus_hours = closest_bus.split("T")[1].split(":")[0]
closest_bus_mins = closest_bus.split("T")[1].split(":")[1]
time_to_wait_hours = (closest_bus_hours.to_i - current_time_hours.to_i)
time_to_wait_mins = (closest_bus_mins.to_i - current_time_mins.to_i)
time_to_wait_mins *= -1 if time_to_wait_mins < 0
time_to_wait = "#{time_to_wait_hours} hours and #{time_to_wait_mins} minutes away"
puts time_to_wait
