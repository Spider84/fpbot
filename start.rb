require 'appium_lib'
require 'selenium-webdriver'
require 'colorize'

def wait_for(timeout = 20)
  begin
    Selenium::WebDriver::Wait.new(timeout: timeout).until { yield }
  rescue Selenium::WebDriver::Error::TimeoutError
    return false
  end
end

@capabilities = {
  caps: {
    platformName: 'android',
    deviceName: '*',
    version: '7.0',
    udid: "#{ARGV[0]}",
    app: "/code/apks/facebook-arm.apk",
    appActivity: '.LoginActivity',
    appPackage: 'com.facebook.katana',
    automationName: 'UiAutomator2',
    adbPort: '5037',
    systemPort: "#{rand(8201..8210)}",
    mjpegServerPort: "#{rand(1201..1210)}",
    newCommandTimeout: 20000,
    autoGrantPermissions: true,
    fastReset: false,
    noReset: true,
    fullReset: false,
    printPageSourceOnFindFailure: true,
    normalizeTagNames: true
  },
  appium_lib: {
    server_url: 'http://127.0.0.1:4444/wd/hub',
    wait_timeout: 300,
    wait_interval: 100,
    newCommandTimeout: 3000
  }
}

# @capabilities = {
#   caps: {
#     platformName: 'android',
#     deviceName: 'f1f690c7',
#     version: '7.0',
#     app: "/code/apks/facebook-arm.apk",
#     appActivity: '.LoginActivity',
#     appPackage: 'com.facebook.katana',
#     automationName: 'UiAutomator2',
#     adbPort: '5037',
#     systemPort: 8201,
#     newCommandTimeout: 20000,
#     autoGrantPermissions: true,
#     fastReset: false,
#     noReset: true,
#     fullReset: false,
#     printPageSourceOnFindFailure: true
#   }
# }

# threads = []
# 3.times do
#   threads << Thread.new do
  begin
    @appium_driver = Appium::Driver.new(@capabilities, false)
    @appium_driver
    puts @appium_driver.remote_status
    @driver = @appium_driver.start_driver
    puts @driver.inspect
    puts "SESSION CAPABILITIES #{@driver.session_capabilities}"
    wait_for(40) { @driver.find_elements(:xpath => "//*[@content-desc='Create New Facebook Account']").count > 0 }
    @driver.find_elements(:xpath => "//*[@content-desc='Create New Facebook Account']").first.click
    wait_for {@driver.find_elements(:xpath => "//*[@text='Next']").count > 0}
    # @logger.screenshot
    @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    @driver.quit
  rescue => ex
    puts ex.message
    @driver.quit
   end
# end
#
# threads.each(&:join)