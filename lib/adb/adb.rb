module Farmpage
  class ADB

    def initialize(logger)
      @devices = []
      @logger = logger
      %x[adb kill-server]
      %x[adb devices]
      system("kill -9 $(pgrep -f 'adb')")
      system("kill -9 $(pgrep -f 'selenium-server-standalone')")
      system("kill -9 $(pgrep -f 'appium')")
      system("rm configs/*")
      sleep(2)
      self.start_grid
      self.check_ips
    end

    def devices
      @devices
    end

    private

    def check_ips
      self.list_devices.each do |device|
        ip = %x[adb -s #{device} shell ip addr show wlan0 | grep "inet\s" | awk '{print $2}' | awk -F'/' '{print $1}']
        @logger.debug "Device IP: #{ip}"
        @devices << Farmpage::Device.new(device, ip.chomp, rand(50000..60000), @grid_port, @logger)
      end
    end

    def start_grid
      @grid_port = rand(2500..2600)
      @grid_port = "4444"
      system("java -jar #{REAL_ROOT}/bin/selenium-server-standalone.jar -role hub -port #{@grid_port} -host 127.0.0.1 &")
      sleep(3)
      puts "Sleeped 3 seconds"
    end

    def list_devices
      devs = %x[adb devices]
      count = 0
      devices = []
      devs.split("\n").each do |line|
        count = count + 1
        next if count == 1
        res = line.split("\t")
        if res.last == 'device'
          devices << res.first
        end
      end
      devices
    end

  end
end
