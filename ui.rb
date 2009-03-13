require 'rubygems'
require 'digger'
require 'sinatra'

get '/' do
  erb :search
end

post '/search' do
  digger = Digger.new
  t0 = Time.now
  @results = digger.search(params[:q])
  t1 = Time.now
  @time_taken = "#{"%6.2f" % (t1 - t0)} secs"
  erb :search
end