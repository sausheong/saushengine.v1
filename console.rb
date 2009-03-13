require 'digger'
require 'pp'

digger = Digger.new
t0 = Time.now
results = digger.search(ARGV[0])
t1 = Time.now
time_taken = "#{"%6.2f" % (t1 - t0)} secs"
puts "Searching for '#{ARGV[0]}' took #{time_taken}" unless results.nil?
puts "Search results:"
results.each { |result|
  puts "- #{Site.get(result[0]).url} (#{"%4.3f" % result[1]})"
} unless results.nil?