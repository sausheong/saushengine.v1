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

error MysqlError do
    'Can\'t find this in the index, try <a href=\'/\'>again</a>'
end

error do
    'Something whacked happened dude, try <a href=\'/\'>again</a>'
end

not_found do
    'Can\'t find this dude, try <a href=\'/\'>again</a>'
end

get '/info' do
  "There are #{Page.count} pages in the index."
end