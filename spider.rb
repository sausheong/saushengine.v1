require 'rubygems'
require 'index'

LAST_CRAWLED_PAGES = 'seed.yml'
DO_NOT_CRAWL_TYPES = %w(.pdf .doc .xls .ppt .mp3 .m4v .avi .mpg .rss .xml .json .txt .git .zip .md5 .asc .jpg .gif .png)
USER_AGENT = 'saush-spider'

class Spider
  
  # start the spider
  def start
    Hpricot.buffer_size = 204800
    process(YAML.load_file(LAST_CRAWLED_PAGES))
  end

  # process the loaded pages
  def process(pages)
    robot = Robots.new USER_AGENT
    until pages.nil? or pages.empty? 
      newfound_pages = []
      pages.each { |page|
        begin
          if add_to_index?(page) then          
            uri = URI.parse(page)
            host = "#{uri.scheme}://#{uri.host}"
            open(page, "User-Agent" => USER_AGENT) { |s|
              (Hpricot(s)/"a").each { |a|                
                url = scrub(a.attributes['href'], host)
                newfound_pages << url unless url.nil? or !robot.allowed? url or newfound_pages.include? url
              }
            } 
          end
        rescue => e 
          print "\n** Error encountered crawling - #{page} - #{e.to_s}"
        rescue Timeout::Error => e
          print "\n** Timeout encountered - #{page} - #{e.to_s}"
        end
      }
      pages = newfound_pages
      File.open(LAST_CRAWLED_PAGES, 'w') { |out| YAML.dump(newfound_pages, out) }
    end    
  end

  # add the page to the index
  def add_to_index?(url)
    print "\n- indexing #{url}" 
    t0 = Time.now
    page = Page.find(scrub(url))
    
    # if the page is not in the index, then index it
    if page.new_record? then    
      index(url) { |doc_words, title|
        dsize = doc_words.size.to_f
        puts " [new] - (#{dsize.to_i} words)"
        doc_words.each_with_index { |w, l|    
          printf("\r\e - %6.2f%",(l*100/dsize))
          loc = Location.new(:position => l)
          loc.word, loc.page, page.title = Word.find(w), page, title
          loc.save
        }
      }
    
    # if it is but it is not fresh, then update it
    elsif not page.fresh? then
      index(url) { |doc_words, title|
        dsize = doc_words.size.to_f
        puts " [refreshed] - (#{dsize.to_i} words)"
        page.locations.destroy!
        doc_words.each_with_index { |w, l|    
          printf("\r\e - %6.2f%",(l*100/dsize))
          loc = Location.new(:position => l)
          loc.word, loc.page, page.title = Word.find(w), page, title
          loc.save
        }        
      }
      page.refresh
      
    #otherwise just ignore it
    else
      puts " - (x) already indexed"
      return false
    end
    t1 = Time.now
    puts "  [%6.2f sec]" % (t1 - t0)
    return true          
  end
  
  # scrub the given link
  def scrub(link, host=nil)
    unless link.nil? then
      return nil if DO_NOT_CRAWL_TYPES.include? link[(link.size-4)..link.size] or link.include? '?' or link.include? '/cgi-bin/' or link.include? '&' or link[0..8] == 'javascript' or link[0..5] == 'mailto'
      link = link.index('#') == 0 ? '' : link[0..link.index('#')-1] if link.include? '#'
      if link[0..3] == 'http'
        url = URI.join(URI.escape(link))                
      else
        url = URI.join(host, URI.escape(link))
      end
      return url.normalize.to_s
    end
  end

  # do the common indexing work
  def index(url)
    open(url, "User-Agent" => USER_AGENT){ |doc| 
      h = Hpricot(doc)
      title, body = h.search('title').text.strip, h.search('body')
      %w(style noscript script form img).each { |tag| body.search(tag).remove}
      array = []
      body.first.traverse_element {|element| array << element.to_s.strip.gsub(/[^a-zA-Z ]/, '') if element.text? }
      array.delete("")
      yield(array.join(" ").words, title)
    }    
  end  
end

$stdout.sync = true 
spider = Spider.new
spider.start
