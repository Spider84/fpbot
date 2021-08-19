# require 'highlander'
require 'rubygems'
require 'faraday'
require 'active_support/inflector'
require 'json'
require 'colorize'
require_relative 'lib/exceptions'
require_relative 'lib/loggers/logman'
require_relative 'lib/loggers/prepare'
require_relative 'lib/processor'
require_relative 'lib/processors/Facebook/facebook'
require_relative 'lib/adb/adb'
require_relative 'lib/adb/device'
require 'telegram/bot'
require 'cloudinary'
require 'thread'
require 'thwait'

FARMPAGE = ENV["production"] ? "farmpage.net" : "127.0.0.1:8092"
ROOT = Dir.pwd
REAL_ROOT = '/code/fpbot_original_release'

start = Time.now

puts "Check if process_task.rb already running"
puts `pwd`
if File.exist?("./running")
  puts "Process already running. Exiting"
  exit
else
  puts "No process is running yet"
  system("touch ./running")
end
puts 'ls -al'

Cloudinary.config do |config|
  config.cloud_name = 'dkhgvvcwf'
  config.api_key = '275168863736691'
  config.api_secret = 'oWlZyF_KDRgj4zryZBYMbdqsG4w'
  config.cdn_subdomain = true
end


# proxies = [
#   'http://node-ru-230.astroproxy.com:11693/api/changeIP?apiToken=2ffc6c2e0ec45555',
#   'http://node-ru-210.astroproxy.com:10685/api/changeIP?apiToken=2ffc6c2e0ec45555',
#   'http://node-ru-175.astroproxy.com:11151/api/changeIP?apiToken=2ffc6c2e0ec45555',
#   'http://node-ru-87.astroproxy.com:10735/api/changeIP?apiToken=2ffc6c2e0ec45555'
# ]
#
# proxies.each do |reload_link|
#   puts "Realoadind #{reload_link}"
#   puts Faraday.get(reload_link).body
# end

prepare_logger = Farmpage::PrepareLogger.new
adb = Farmpage::ADB.new(prepare_logger)
threads = []
adb.devices.each do |device|
  threads << Thread.new {
    device.tcpip
    device.connect
    device.flush_uiautomator
    device.grant_permissions
    device.prepare_node
    device.start_node
  }
end
ThreadsWait.all_waits(*threads)

system("iptables -t nat -F WIFI_PROXY")

total = 0
prepare_logger.debug "Waiting for #{adb.devices.count} nodes to register"
20.times do
  prepare_logger.debug "Checking nodes count ... "
  total = JSON.parse(Faraday.get("http://localhost:4444/grid/api/hub").body)['slotCounts']['total']
  prepare_logger.debug "Now #{total} nodes registered"
  if total == adb.devices.count
    prepare_logger.debug "Got #{adb.devices.count} nodes. Proceeding"
    break
  end
  sleep(1)
end
if total != adb.devices.count
  prepare_logger.debug "Not all nodes registered. Increase retry times"
  puts "Removing `running` flag"
  system("rm ./running")
  exit
end


threads = []
cnt = 0
adb.devices.each do |device|
  threads << Thread.new(device = device) do
    begin
      url = "https://#{FARMPAGE}/api/task"
      api_response = JSON.parse(Faraday.get(url).body)
      logger = Farmpage::Logger.new(api_response['task'], device)
      logger.noise api_response.inspect
      processor = Farmpage::Processor.new(api_response, logger, device.udid, device.ip, device.port, device.appium_port, cnt)
      processor.process!
    rescue NoMethodError => exception
      logger.critical exception
      Faraday.get("https://#{FARMPAGE}/api/register/failure/task/#{api_response['task']}/reason/contact_techincal_support")
    rescue Farmpage::Exceptions::SMSTimeout => exception
      # to delete AVD image from HDD
      logger.critical exception
      Faraday.get("https://#{FARMPAGE}/api/register/failure/task/#{api_response['task']}/reason/sms_timeout")
    rescue Farmpage::Exceptions::NoSMSnumbers
      Faraday.get("https://#{FARMPAGE}/api/task/retry/task/#{api_response['task']}/reason/no_number_for_sms")
    rescue Farmpage::Exceptions::Banned
      logger.noise "Banned Tag Found. Exiting"
      Faraday.get("https://#{FARMPAGE}/api/register/failure/task/#{api_response['task']}/reason/banned_while_signup")
    rescue Selenium::WebDriver::Error::UnknownError
      Faraday.get("https://#{FARMPAGE}/api/task/retry/task/#{api_response['task']}/reason/unknown_error_in_selenium")
    rescue Farmpage::Exceptions::BadProxy
      Faraday.get("https://#{FARMPAGE}/api/task/retry/task/#{api_response['task']}/reason/bad_proxy")
    rescue Farmpage::Exceptions::CouldNotLaunchEmulator
      Faraday.get("https://#{FARMPAGE}/api/task/retry/task/#{api_response['task']}/reason/could_not_launch_emulator")
    rescue Exception => exception
      puts exception.message
      puts "`#{exception.backtrace.join("\n\t")}`"
      # logger.critical exception
      Faraday.get("https://#{FARMPAGE}/api/register/failure/task/#{api_response['task']}/reason/contact_technical_support")
    end

    finish = Time.now
    diff = finish - start
    tooktime = diff.round
    Faraday.get("https://#{FARMPAGE}/api/tooktime/#{tooktime}/task/#{api_response['task']}")
  end
  cnt += 1

end

ThreadsWait.all_waits(*threads)

puts "Removing `running` flag"
system("rm ./running")