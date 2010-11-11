#!/usr/bin/ruby

require 'config.rb'
@logger.info "Visiting started"

agent = Mechanize.new { |agent| agent.follow_meta_refresh = true; }


DB = Sequel.connect('sqlite://girls.db')
GIRLS = DB[:girls]


agent.get(SITE) do |login_page|
  my_page = login_page.form_with(:action => '/a-logon/') do |f|
    f['login'] = LOGIN
    f['password'] = PASS
  end.click_button

  @logger.info "Logged in"

  sleep(2 + rand(2))

  unviewed_count = GIRLS.filter(:viewed => false).count
  done = 0
  GIRLS.filter(:viewed => false).each do |girl_row|
    agent.transact do
      agent.get(SITE + girl_row[:login]) do |girl_page|
        items = girl_page.root.css('dl')
        def items.get_item txt
          results = self.select { |i| i.css('dt').text =~ Regexp.new(txt) }
          return nil if results.empty?
          return results.first.css('dd').text
        end
        
        girl_row[:seek] = items.get_item "Я ищу"
        girl_row[:for] = items.get_item "Цель знакомства"
        girl_row[:height] = items.get_item "Рост"
        girl_row[:weight] = items.get_item "Вес"
        girl_row[:tits] = items.get_item "Размеры"
        girl_row[:sex_preferences] = items.get_item "В сексе мне нравится"
        girl_row[:sex_bonus] = items.get_item "Также меня возбуждает"
        girl_row[:life_targets] = items.get_item "Жизненные цели"
        girl_row[:drugs] = items.get_item "Наркотики"
        girl_row[:sex_frequency] = items.get_item "Как часто вы бы хотели заниматься сексом"
        girl_row[:sex_experience] = items.get_item "Наличие гетеросексуального опыта"
        girl_row[:children] = items.get_item "Дети"
        girl_row[:money] = items.get_item "Доход"
        girl_row[:house] = items.get_item "Жилищные условия"
        girl_row[:smoking] = items.get_item "Курение"
        girl_row[:alcohol] = items.get_item "Алкоголь"
        girl_row[:viewed] = true
        GIRLS.filter(:login => girl_row[:login], :site => SITE).update(girl_row)
        done +=1 
        @logger.info "#{girl_row[:name]} (#{girl_row[:age]}) - #{girl_row[:for]}"
        @logger.info "==== #{done} of #{unviewed_count} ====" if done % 10 == 0
        sleep(1 + rand(1))
      end
    end
  end
end

