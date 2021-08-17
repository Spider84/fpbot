require 'rubygems'
require 'json'


adb = Farmpage::ADB.new
adb.check_ips
adb.start_grid
threads = []
adb.devices.each do |device|
  Thread.new {
    device.tcpip
    device.connect
    device.grant_permissions
    device.flush_uiautomator
    device.prepare_node
    device.start_node
  }
end
