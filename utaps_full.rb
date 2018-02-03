# helpful links:
# https://github.com/SeleniumHQ/selenium/wiki/Ruby-Bindings
# https://www.amberbit.com/blog/2014/2/12/automate-tasks-on-the-web-with-ruby-and-capybara/
# https://github.com/jnicklas/capybara
# cheat sheet: https://gist.github.com/zhengjia/428105
# within: http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Session#within-instance_method

# “To seek contentment is to release the novelty that lies within monotony” 
# ― Ilyas Kassam

# directions:
# - set up ruby
# - ensure you have the right gems (capybara, selenium-webdriver)
# - create a basic script: u = Utaps.new('111223333','p@ssw0rd','22301')


require 'capybara'
require 'selenium-webdriver'
require 'date'

class Utaps
  attr_reader :url, :social, :session
  
  def initialize(social, password, zip)
    @url = 'https://arowsr.afrc.af.mil/arows-r/dod_consent.do;jsessionid=OLOi58P0Xazp15k0ZkWWDH-hZAjWz-KAZeYJ7yTSw5HUjLHv_ref!-1259174922?actionButton=OK'
    @social = social
    @password = password
    @session = setup_services
    @zip = zip
    @valuestr = 'na|US|20301|Pentagon|DC|Dist of Columbia|'
    # this is what value of location you need in the utaps form (lame on my end, but works)
  end

  def format_date(day, month)
    # 'Friday, January 07, 2017' <-- specific format
    t = Time.local(2017, month, day)
    t.strftime('%A, %B %d, %Y')
  end

  def build_year
    # every other friday, but only 24 of these
    every_other_friday[0..23].each do |day|
      puts "building: #{day.to_s}"
      build_day(day)
    end
  end

  def every_other_friday
    start_date = Date.new(2016,10,1) # beginning of the fiscal year
    end_date = Date.new(2017,10,1)-1 # end of fiscal year
    datesByWeekday = (start_date..end_date).group_by(&:wday)[5]
    return datesByWeekday.values_at(* datesByWeekday.each_index.select {|i| i.even?})
  end

  def build_day(date)
    dt = format_date(date.day, date.month)
    if @session.first(:css, "td[title='#{dt}']")
      build_idt(dt)
    else
      puts "#{dt} already used"
    end
  end
  
  def build_idt(dt)
    @session.within("td[title='#{dt}']") do
      @session.find('a').click
    end
    new_window=@session.windows.last
    @session.within_window new_window do
      @session.within('#form1') do
        @session.fill_in('txtNumPeriods', with: '2')
        @session.choose('ctrlLocation_radChooseLocation_2')
        @session.fill_in('ctrlLocation_txtZipcode', with: @zip)
        @session.find(:css, '#ctrlLocation_btnSearchZip').click
        @session.find("option[value='#{@valuestr}']").click
        @session.click_button 'btnSubmit'
        @session.click_button 'btnSaveClose'
      end
    end
  end

  def setup_services
    # monkey patch to keep the browser up
    Capybara::Selenium::Driver.class_eval do
      def quit
        puts "Press RETURN to quit the browser"
        $stdin.gets
        @browser.quit
      rescue Errno::ECONNREFUSED
        # Browser must have already gone
      end
    end

    Capybara.register_driver :selenium do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome)
    end

    return Capybara::Session.new(:selenium)
  end

  def login
    # use instance exec here ?
    @session.visit(@url)
    # fill in name 'username in logonForm' with social
    @session.within('#passwordLogin > form') do
      @session.fill_in('username', with: @social)
      @session.fill_in('password', with: @password)
      @session.click_button 'Login'
    end
    @session.visit 'https://arowsr.afrc.af.mil/arows-r/utaps.do'
    @session.click_link 'Login to UTAPS'
    @session.visit 'https://arowsr.afrc.af.mil/arows-r/utaps_redirect.do'
    @session.click_button 'btnAccept'
    @session.visit 'https://utapsima.afrc.af.mil/utaps-ima/IMASchedule.aspx'
    @session.find('#MainContent_imgNext').click # <-- not working
    @session.find('#MainContent_imgBtnAddIDT').click
  end

end
