module Farmpage

  class Device
    attr_accessor :udid
    attr_accessor :ip
    attr_accessor :port
    attr_accessor :appium_port

    def initialize(udid, ip, port, hub_port, logger)
      @udid = udid
      @logger = logger
      @ip = ip
      @port = port
      @hub_port = hub_port
    end

    def tcpip
      output = %x[adb -s #{self.udid} tcpip #{self.port}]
      @logger.debug output
    end

    def connect
      output = %x[adb -s #{self.udid} connect #{self.ip}:#{self.port}]
      @logger.debug output
      # output = %x[adb -s #{self.udid} uninstall com.facebook.katana]
      # @logger.debug output
    end

    def grant_permissions
      puts "adb -s #{self.udid} shell pm clear com.facebook.katana"
      output = %x[adb -s #{self.udid} shell pm clear com.facebook.katana]
      @logger.debug output

      puts "adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.WRITE_CONTACTS"
      output = %x[adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.WRITE_CONTACTS]
      @logger.debug output

      puts "adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.READ_CONTACTS"
      output = %x[adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.READ_CONTACTS]
      @logger.debug output

      puts "adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.READ_PHONE_STATE"
      output = %x[adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.READ_PHONE_STATE]
      @logger.debug output

      puts "adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.ACCESS_FINE_LOCATION"
      output = %x[adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.ACCESS_FINE_LOCATION]
      @logger.debug output

      puts "adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.ACCESS_COARSE_LOCATION"
      output = %x[adb -s #{self.udid} shell pm grant com.facebook.katana android.permission.ACCESS_COARSE_LOCATION]
      @logger.debug output
    end

    def flush_uiautomator
      output = %x[adb -s #{self.udid} uninstall io.appium.uiautomator2.server]
      @logger.debug output
      output = %x[adb -s #{self.udid} uninstall io.appium.uiautomator2.server.test]
      @logger.debug output
    end

    def prepare_node
      conf = {
        capabilities:
          [
            {
              applicationName: "#{self.udid}",
              browserName: "android",
              deviceName: "#{self.udid}",
              version: "7.0",
              maxInstances: 1,
              maxSession: 1,
              platform: "Android"
            }
          ],
        configuration:
          {
            cleanUpCycle: 2000,
            timeout: 30000,
            proxy: "org.openqa.grid.selenium.proxy.DefaultRemoteProxy",
            url: "http://127.0.0.1:#{@hub_port}/wd/hub",
            maxSession: 6,
            port: "#{self.port}",
            "bootstrap-port": "#{rand(10000..20000)}",
            host: "localhost",
            register: true,
            registerCycle: 5000,
            hubPort: "#{@hub_port}",
            hubHost: "localhost",
            "session-override": true
          }
      }
      File.open("#{REAL_ROOT}/configs/#{self.udid}.json", "w") do |f|
        f.write(JSON.pretty_generate(conf))
      end
      @logger.debug "Saved config for #{self.udid}"
    end

    def start_node
      str = "appium --nodeconfig #{REAL_ROOT}/configs/#{self.udid}.json -p #{self.port} --default-capabilities '{\"udid\":\"#{self.udid}\"}' > /dev/null &"
      @logger.debug str
      system(str)
    end

  end

end
