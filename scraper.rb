#!/usr/bin/env ruby

require 'scraperwiki'
require 'mechanize'

def scrape_page(page)
  page.search("tr[@class='normalRow'], tr[@class='alternateRow']").each do |row|
    cells = row.search('td')

    council_reference = cells[0].search("a").text
    if council_reference && council_reference.start_with?("DA", "LL", "VA", "WAPC") #selects planning applications only
      puts "Found #{council_reference}"
      save_record(council_reference, cells)
    else
      puts "skipping non planning application #{council_reference}"
    end
  end
end

def save_record(council_reference, cells)
  record = {
  'council_reference' => council_reference,
  'address' => cells[5].search("a").text,
  'description' => cells[2].text,
  'info_url' => 'https://eservices.fremantle.wa.gov.au/ePropertyPROD/P1/eTrack/eTrackApplicationSearch.aspx?r=P1.WEBGUEST&f=%24P1.ETR.SEARCH.ENQ',
  'comment_url' => 'mailto:info@fremantle.wa.gov.au',
  'date_received' => Date.parse(cells[1].text).strftime("%Y-%m-%d"),
  'date_scraped' => Date.today.to_s,
  }
  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts "Skipping already saved record " + record['council_reference']
  end
end

#scrape first results page
agent = Mechanize.new { |a|
  #a.user_agent_alias = 'Mac Firefox'
}
url = "https://eservices.fremantle.wa.gov.au/ePropertyPROD/P1/eTrack/eTrackApplicationSearchResults.aspx?Field=S&Period=L7&r=P1.WEBGUEST&f=%24P1.ETR.SEARCH.SL7"
page = agent.get(url)
scrape_page(page)

# The above code searches the first 20 applications submitted in the last 7 days.
# There is sometimes more than 20 applications.
# The next 20 applicaitons are obtained by making a doPostform enquiry.
# I have drafted some code (below) which I have not been able to get to work.
# In the meantime, A small number of applicaitons may pass through the cracks. Most will be scraped.

#draft code:
#cp = 1
#np = $page.search("tr[@class='pagerRow'] td[@colspan]").to_s.split('"')[1].to_i
#if np == "" #if there is no second page
  #np = 1
#end
#while cp > np
  #cp+=1
  #sleep 1.0 + rand
  #form = $page.forms.first
  #form["__EVENTTARGET"],form["__EVENTARGUMENT"] = "ctl00$Content$cusResultsGrid$repWebGrid$ctl00$grdWebGridTabularView", "page$#{cp}"
  #$page = agent.submit(form)
  #puts "scraping page number " + cp.to_s
  #scrape_page
#end

#look at these pages for tips:
  #https://blog.scraperwiki.com/2011/11/how-to-get-along-with-an-asp-webpage/
  #http://scraperblog.blogspot.com.au/2012/10/asp-forms-with-dopostback-using-ruby.html
  #http://mechanize.rubyforge.org/Mechanize/Form.html
