#!/usr/bin/ruby

require 'config.rb'

@logger.info "Parsing started"

agent = WWW::Mechanize.new { |agent| agent.follow_meta_refresh = true; }


DB = Sequel.connect('sqlite://girls.db')
GIRLS = DB[:girls]

agent.get(SITE) do |login_page|
  my_page = login_page.form_with(:action => '/a-logon/') do |f|
    f['login'] = LOGIN
    f['password'] = PASS
  end.click_button

  @logger.info "Logged in"

  sleep(2 + rand(2))
  (START_AGE..END_AGE).each do |search_age|
    current_page = 0
    girl_count = 0
    have_results = false
    (0..50).each do |current_page|
      search_address = "http://loveplanet.ru/a-search/d-1/pol-1/spol-2/bage-#{search_age}/tage-#{search_age}/foto-1/newface-1/country-#{REGION[0]}/region-#{REGION[1]}/city-#{REGION[2]}/relig-0/p-#{current_page}/"
      agent.transact do
        agent.get(search_address) do |result_page|
          results = result_page.root.css('.second')
          have_results = results.size > 3
          unless have_results
            @logger.info "No results found on page #{current_page}. Stopping..."
            break
          end
          @logger.info "==== Page #{current_page + 1} ===="
          @logger.info "==== Count: #{results.size} ===="
          results.each do |person|
            url = person.css('.name').first['href']
            girl = GIRLS[:login => url]
            next if girl
            name = person.css('.name').first.text
            datatext = person.css('.user_data').first.text
            age = datatext.scan(/Возраст: (\d+)/)[0][0] if datatext.scan(/Возраст: (\d+)/)[0]
            photo_url = person.css('.friends_foto img').first['src']
            GIRLS.insert :name => name, :age => age, :viewed => false, :site => SITE, :for => photo_url, :login => url
            girl_count += 1
            @logger.info "#{girl_count}: #{name} (#{age || '??'})"
          end
        end
      end
      sleep(1 + rand(2))
    end
    @logger.info "Total results: #{girl_count}"
  end

end
