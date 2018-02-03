# https://github.com/SeleniumHQ/selenium/wiki/Ruby-Bindings
# https://www.amberbit.com/blog/2014/2/12/automate-tasks-on-the-web-with-ruby-and-capybara/
# https://github.com/jnicklas/capybara
# cheat sheet: https://gist.github.com/zhengjia/428105
# within: http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Session#within-instance_method
# #passwordLogin
# //*[@id="passwordLogin"]
# #passwordLogin > form

require 'capybara'
require 'selenium-webdriver'

url = 'https://arowsr.afrc.af.mil/arows-r/dod_consent.do;jsessionid=OLOi58P0Xazp15k0ZkWWDH-hZAjWz-KAZeYJ7yTSw5HUjLHv_ref!-1259174922?actionButton=OK'
social = 'xxxxxxxx'
password = 'xxxxxx'

# not needed
# Selenium::WebDriver::Chrome::Service.executable_path = '/usr/local/bin/chromedriver'

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

session = Capybara::Session.new(:selenium)
session.visit(url)
# fill in name 'username in logonForm' with social
session.within('#passwordLogin > form') do
  session.fill_in('username', with: social)
  session.fill_in('password', with: password)
  session.click_button 'Login'
end
session.visit 'https://arowsr.afrc.af.mil/arows-r/utaps.do'
session.click_link 'Login to UTAPS'
session.visit 'https://arowsr.afrc.af.mil/arows-r/utaps_redirect.do'
session.click_button 'btnAccept'


# fill in name 'password' in logonForm' with password

if session.has_content?("Everyday I strive to input, process and share information")
  puts "All shiny, captain!"
else
  puts ":( no tagline fonud, possibly something's broken"
  exit(-1)
end
