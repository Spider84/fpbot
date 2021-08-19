require 'appium_lib'
require 'selenium-webdriver'

module Farmpage
  class Facebook

    def initialize(task, avd, proxy, logger, device_id, host, port, appium_port, task_num)
      @logger = logger
      @task = task
      @apk_file = task['apk']
      @skin = task['skin']
      @sms_country = task['sms']['country']
      @proxy = proxy
      @device_id = device_id
      @host = host
      @port = port
      @avd = avd
      @appium_port = appium_port
      @task_num = task_num
      @logger.debug "Initializing device"
      @capabilities = {
        caps: {
          platformName: 'android',
          deviceName: "#{@device_id}",
          # version: '7.0',
          app: "/code/apks/facebook_latest.apk",
          appActivity: '.LoginActivity',
          appPackage: 'com.facebook.katana',
          automationName: 'UIAutomator2',
          adbPort: '5037',
          adbExecTimeout: 40000,
          systemPort: "#{rand(8001..9210)}",
          mjpegServerPort: "#{rand(1201..5210)}",
          newCommandTimeout: 20000,
          autoGrantPermissions: true,
          fastReset: false,
          skipUnlock: true,
          noReset: true,
          fullReset: false,
          waitForIdleTimeout: 0,
          printPageSourceOnFindFailure: true,
          normalizeTagNames: true,
          udid: "#{@device_id}"
        },
        appium_lib: {
          server_url: 'http://127.0.0.1:4444/wd/hub',
          wait_timeout: 3000,
          wait_interval: 1000,
          newCommandTimeout: 30000
        }
      }
    end

    def register
      @logger.debug("Starting Appium driver")
      @appium_driver = Appium::Driver.new(@capabilities, false)
      @driver = @appium_driver.start_driver
      if !@driver.app_installed?("com.facebook.katana")
        @logger.debug "Could not install application"
        exit
      else
        @logger.debug "Application Installed. Proceeding"
      end

      device_mac = nil

      @logger.debug "Trying to detect device MAC for interface `#{host}`..."
      IO.popen("ip addr") {|nkf_io|
        ip_addr = nkf_io.read
        addr = ether = nil
        ip_addr.each_line do |line|
          m = line.match /^\s*\d+\:\s+(\w+)\:\s+/
          if m
            addr = ether = nil
            next
          end
          m = line.match /^\s+inet\s+((?:[0-9]{1,3}\.){3}[0-9]{1,3})/
          if m
            addr = m[1]
            next
          end
          m = line.match /^\s+link\/ether\s+((?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2}))/
          if m
            ether = m[1]
            next
          end
          if addr!=nil && ether!=nil
            if host.eql?(addr)
              @logger.debug "Detected device MAC `#{ether}`"
              device_mac = ether
              break
            end
            addr = ether = nil
          end
        end
      }

      if device_mac != nil
        proxy_local_port = 10000 + @task_num
        new_config = %{
redsocks {
      /* `local_ip' defaults to 127.0.0.1 for security reasons,
      * use 0.0.0.0 if you want to listen on every interface.
      * `local_*' are used as port to redirect to.
      */
      local_ip = 10.0.0.1;
      local_port = #{proxy_local_port};

      // listen() queue length. Default value is SOMAXCONN and it should be
      // good enough for most of us.
      // listenq = 128; // SOMAXCONN equals 128 on my Linux box.

      // Enable or disable faster data pump based on splice(2) syscall.
      // Default value depends on your kernel version, true for 2.6.27.13+
      // splice = false;

      // `ip' and `port' are IP and tcp-port of proxy-server
      // You can also use hostname instead of IP, only one (random)
      // address of multihomed host will be used.
      ip = #{task['proxy']['host']};
      port = #{task['proxy']['port']};

      // known types: socks4, socks5, http-connect, http-relay
      type = socks5;

      login = "#{task['proxy']['login']}";
      password = "#{task['proxy']['password']}";

      // known ways to disclose client IP to the proxy:
      //  false -- disclose nothing
      // http-connect supports:
      //  X-Forwarded-For  -- X-Forwarded-For: IP
      //  Forwarded_ip     -- Forwarded: for=IP # see RFC7239
      //  Forwarded_ipport -- Forwarded: for="IP:port" # see RFC7239
      // disclose_src = false;

      // various ways to handle proxy failure
      //  close -- just close connection (default)
      //  forward_http_err -- forward HTTP error page from proxy as-is
      on_proxy_fail = close;
}
        }
        writer = Fifo.new('/var/run/redsocks.socket', :w, :nowait)
        writer.puts new_config

        system("iptables -t nat -A WIFI_PROXY -p tcp -s #{host} -m mac --mac-source #{device_mac} -j REDIRECT --to-ports #{proxy_local_port}")
      end
      
      system("adb -s #{@device_id} shell pm grant com.facebook.katana android.permission.WRITE_CONTACTS")
      system("adb -s #{@device_id} shell pm grant com.facebook.katana android.permission.READ_CONTACTS")
      system("adb -s #{@device_id} shell pm grant com.facebook.katana android.permission.READ_PHONE_STATE")
      system("adb -s #{@device_id} shell pm grant com.facebook.katana android.permission.ACCESS_FINE_LOCATION")
      system("adb -s #{@device_id} shell pm grant com.facebook.katana android.permission.ACCESS_COARSE_LOCATION")
      @first_name = @task['user']['name'].split(' ').first
      @task_id = @task['task']
      @last_name = @task['user']['name'].split(' ').last
      @password = @task['user']['passsword']
      self.click_create_account
      found_mobile = wait_for(3) { @driver.find_elements(:xpath => "//android.widget.TextView[@content-desc='Enter Your Mobile Number']").count > 0}
      self.retrieve_number
      @logger.debug "Trying to register account `#{@first_name} #{@last_name}` with login `#{@number}` password `#{@password}`"
      if found_mobile
        self.enter_mobile_number
        # self.enter_email
        self.enter_password
        self.enter_name
        self.choose_dob
        self.choose_sex
        self.click_signup
        self.wait_for_code
        self.skip_dialogs
        self.confirm_sms
        # self.skip_rest
      else
        self.enter_name
        self.choose_dob
        self.choose_sex
        self.enter_mobile_number
        # self.enter_email
        self.enter_password
        self.click_signup
        # self.wait_for_email_code
        self.wait_for_code
        self.skip_dialogs
        self.confirm_sms
        # self.skip_rest
      end
      Faraday.get("https://#{FARMPAGE}/api/register/success/task/#{@task['task']}")
      self.save_creds(@task_id, @number, @password)
    end

    def newsfeed
      @appium_driver = Appium::Driver.new({caps: @apk}, false)
      @driver = @appium_driver.start_driver
      wait_for(40) {@driver.find_elements(:class => "//androidx.viewpager.widget.ViewPager").count > 0}
      swipe_element = @driver.find_elements(:class => "//androidx.viewpager.widget.ViewPager").first
      puts swipe_element.inspect
      @logger.debug "Trying to swipe newsfeed"
      @driver.touch_actions.scroll(swipe_element, 10, 100).perform
      # @logger.screenshot
      self.finish(0)
    end

    private

    def finish(text)
      con = Faraday.new
      con.post do |req|
        req.url "http://#{FARMPAGE}/api/task/finish/task/#{@task['task']}"
        req.body = "message=#{text}"
      end
    end

    def save_creds(task, login, pass)
      con = Faraday.new
      con.post do |req|
        req.url "https://#{FARMPAGE}/api/creds/task/#{task}"
        req.body = "login=#{login}&password=#{pass}"
      end
    end

    def retrieve_email
      @logger.debug("Trying to retrieve email from Kopeechka")
      query = "http://api.kopeechka.store/mailbox-get-email?site=farmpage.net&mail_type=gmail.com&token=ace079cb48f56cc4396e772d7f872458&type=JSON&&api=2.0"
      @logger.debug query
      resp = JSON.parse(Faraday.get(query).body)
      @logger.debug resp.inspect
      if resp['status'] == 'OK'
        @email = resp['mail']
        @email_task_id = resp['id']
      end
    end

    def retrieve_number
      @logger.debug("Trying to retrieve number for SMS")
      resp = Faraday.get("https://smshub.org/stubs/handler_api.php?api_key=90553U0555c00e0f56b5ebd09bea9c8afc3e5a&action=getBalance")
      was_balance = resp.body.split(":").last
      puts was_balance
      sms = nil
      10.times do
        url = "https://smshub.org/stubs/handler_api.php?api_key=90553U0555c00e0f56b5ebd09bea9c8afc3e5a&action=getNumber&service=fb&country=#{@sms_country}"
        sms = Faraday.get("https://smshub.org/stubs/handler_api.php?api_key=90553U0555c00e0f56b5ebd09bea9c8afc3e5a&action=getNumber&service=fb&country=#{@sms_country}").body
        @logger.log url
        @logger.say "Trying to get number .. "
        break if sms.split(":").first == 'ACCESS_NUMBER'
        @logger.answer 'Could not get number'
        sleep(2)
      end
      @access_code = sms.split(":")[1]
      @number = sms.split(":")[2]
      if @number.nil?
        @logger.noise "Could not get any number for SMS. Exiting."
        raise Farmpage::Exceptions::NoSMSnumbers.new("Could not get any number for SMS")
      else
        resp = Faraday.get("https://smshub.org/stubs/handler_api.php?api_key=90553U0555c00e0f56b5ebd09bea9c8afc3e5a&action=getBalance")
        now_balance = resp.body.split(":").last
        sms_price = was_balance.to_f - now_balance.to_f
        @logger.debug "Price of SMS was #{sms_price.round(1)} RUB"
        Faraday.get("https://#{FARMPAGE}/api/sms/task/#{@task['task']}/price/#{sms_price.round(1)}/number/#{@number}")
        @logger.debug "Got number `#{@number}`"
      end
      @logger.debug "Access code is #{@access_code}"
      @logger.debug "Registering Facebook account"
    end

    def click_create_account
      @logger.debug("Clicking Create Account button")
      found_continue = wait_for(1) {@driver.find_elements(:xpath => "//*[@text='CONTINUE']").count > 0}
      @driver.find_elements(:xpath => "//*[@text='CONTINUE']").first.click if found_continue
      wait_for(40) {@driver.find_elements(:xpath => "//*[@content-desc='Create New Facebook Account']").count > 0}
      @driver.find_elements(:xpath => "//*[@content-desc='Create New Facebook Account']").first.click
      wait_for {@driver.find_elements(:xpath => "//*[@text='Next']").count > 0}
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    end

    def enter_email
      @logger.debug "Switching to Email mode"
      wait_for(40) {@driver.find_elements(:xpath => "//*[@text='Sign Up With Email Address']").count > 0}
      @driver.find_elements(:xpath => "//*[@text='Sign Up With Email Address']").first.click
      wait_for { @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").count > 0}
      mobile_element = @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").first
      mobile_element.clear
      mobile_element.send_keys(@email)
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    end

    def enter_mobile_number
      @logger.debug "Entering mobile number"
      wait_for { @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").count > 0}
      mobile_element = @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").first
      mobile_element.clear
      mobile_element.send_keys(@number)
      puts @driver.page_source.colorize(:cyan)
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    end

    def wait_for_code
      @logger.debug "Waiting for confirmation SMS"
      code = ''
      got_code = false
      8.times do
        code = Faraday.get("https://smshub.org/stubs/handler_api.php?api_key=90553U0555c00e0f56b5ebd09bea9c8afc3e5a&action=getStatus&id=#{@access_code}").body
        @logger._say "Checking status .."
        if code != "STATUS_WAIT_CODE"
          got_code = true
          break
        end
        @logger.answer('not yet', :green)
        sleep(10)
      end
      raise Farmpage::Exceptions::SMSTimeout.new("Tryied to get status of #{@number} with no luck. Exiting.") if !got_code
      @confirmation_code = code.split(":").last
      @logger.debug "Got confirmation code: `#{@confirmation_code}`"
    end

    def wait_for_email_code
      @logger.debug "Waiting for code from email"
      code = ''
      got_code = false
      8.times do
        code = JSON.parse(Faraday.get("http://api.kopeechka.store/mailbox-get-message?full=1&id=#{@email_task_id}&token=ace079cb48f56cc4396e772d7f872458&type=JSON&api=2.0").body)
        puts code.inspect
        @logger._say "Checking status .."
        if code['status'] != "ERROR"
          got_code = true
          break
        end
        @logger.answer('not yet', :green)
        sleep(10)
      end
      raise Farmpage::Exceptions::SMSTimeout.new("Tryied to get status of #{@number} with no luck. Exiting.") if !got_code
      @confirmation_code = code.split(":").last
      @logger.debug "Got confirmation code: `#{@confirmation_code}`"
    end

    def confirm_sms
      @logger.debug "Confirming with code `#{@confirmation_code}`"
      wait_for { @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").count > 0}
      confirm_element = @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").first
      confirm_element.send_keys(@confirmation_code)
      wait_for { @driver.find_elements(:xpath => "//*[@text='Confirm']").count > 0 }
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Confirm']").first.click
    end

    def skip_rest
      found = wait_for(50) { @driver.find_elements(:xpath => "//*[@text='Skip']").count > 0 }
      if found
        puts "Found first Skip button"
        @driver.find_elements(:xpath => "//*[@text='Skip']").first.click
      else
        puts "No first Skip button"
      end
      found = wait_for(1) { @driver.find_elements(:xpath => "//*[@text='Skip']").count > 0 }
      if found
        puts "Found second Skip button"
        @driver.find_elements(:xpath => "//*[@text='Skip']").first.click
      else
        puts "No second Skip button"
      end
      found = wait_for(1) { @driver.find_elements(:xpath => "//*[@text='SKIP']").count > 0 }
      if found
        puts "Found third Skip button"
        @driver.find_elements(:xpath => "//*[@text='SKIP']").first.click
      else
        puts "No third Skip button"
      end
      found = wait_for(1) { @driver.find_elements(:xpath => "//*[@text='NOT NOW']").count > 0 }
      if found
        puts "Found first NOT NOW button"
        @driver.find_elements(:xpath => "//*[@text='NOT NOW']").first.click
      else
        puts "No NOT NOW button"
      end
      found = wait_for(1) { @driver.find_elements(:xpath => "//*[@text='Not Now']").count > 0 }
      puts found
      if found
        puts "Found first Not Now button"
        @driver.find_elements(:xpath => "//*[@text='Not Now']").first.click
      else
        puts "No Not Now button"
      end
      found = wait_for(5) { @driver.find_elements(:xpath => "//*[@text='OK']").count > 0 }
      puts found
      if found
        puts "Found first OK button"
        @driver.find_elements(:xpath => "//*[@text='OK']").first.click
      else
        puts "No OK button"
      end
    end

    def skip_dialogs
      @logger.debug "Skipping standard dialogs"
      sleep(2)
      wait_for(100) {@driver.find_elements(:class => "android.widget.Button").count > 0}
      @driver.find_elements(:class => "android.widget.Button").first.click
      to_click = wait_for {
        @driver.find_elements(:xpath => "//*[@content-desc='OK']").count > 0
        @driver.find_elements(:xpath => "//*[@content-desc='OK']").first
      }
      # @logger.screenshot
      to_click.click
    end

    def enter_password
      @logger.debug "Entering password"
      wait_for { @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").count > 0 }
      password_element = @driver.find_elements(:xpath => "//android.widget.EditText[@class='android.widget.EditText']").first
      password_element.send_keys(@password)
      wait_for { @driver.find_elements(:xpath => "//*[@text='Next']").count > 0 }
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    end

    def click_signup
      @logger.debug "Clicking Signup button"
      @logger.debug @driver.inspect
      wait_for { @driver.find_elements(:xpath => "//*[@text='Sign Up']").count > 0 }
      @logger.debug "INSPECT"
      @logger.debug @driver.inspect
      # @logger.screenshot(@device_id)
      @driver.find_elements(:xpath => "//*[@text='Sign Up']").first.click
      # @lgger.debug "After click"
      @logger.noise "Waiting for `Creating Your Account` to disappear ... "
      wait_for(100) do
        puts @driver.find_elements(:xpath => "//*[@text='Creating your account…']").inspect
        @driver.find_elements(:xpath => "//*[@text='Creating your account…']").count == 0
      end
      @logger.noise "Dissapeared"
      @logger.noise "Waiting for `Signing In` to disappear ... "
      wait_for(100) do
        puts @driver.find_elements(:xpath => "//*[@text='Signing in…']").inspect
        @driver.find_elements(:xpath => "//*[@text='Signing in…']").count == 0
      end
      raise Farmpage::Exceptions::Banned.new if wait_for(3) { @driver.find_elements(:xpath => "//*[@text='Enter Your Mobile Number']").count > 0 }
      @logger.noise "Checking if `Number in use` tag present ... none"
      raise Farmpage::Exceptions::Banned.new if wait_for(3) { @driver.find_elements(:xpath => "//*[@text='No Internet Connection']").count > 0 }
      @logger.noise "Checking if `Internet Connection` tag present ... none"
      raise Farmpage::Exceptions::Banned.new if wait_for(3) { @driver.find_elements(:xpath => "//*[@text='Something Went Wrong']").count > 0 }
      @logger.noise "Checking if `Something Went wrong` tag present ... none"
      raise Farmpage::Exceptions::Banned.new if wait_for(3) { @driver.find_elements(:xpath => "//*[@content-desc='LEARN MORE ABOUT OUR COMMUNITY STANDARDS']").count > 0 }
      raise Farmpage::Exceptions::Banned.new if wait_for(3) { @driver.find_elements(:xpath => "//*[@text='The action attempted has been deemed abusive or is otherwise disallowed']").count > 0 }
      raise Farmpage::Exceptions::Banned.new if wait_for(3) { @driver.find_elements(:xpath => "//*[@content-desc='Continue']").count > 0 }
      puts @driver.page_source
      @logger.noise "Checking if `We Need More Information` tag present ... none"
      @logger.noise "Checking if account is banned .. no"
      @logger.noise "Proceeding"
    end

    def enter_name
      @logger.debug "Entering firstname and lastname"
      wait_for { @driver.find_elements(:class => "android.widget.EditText").count > 0 }
      first_name_element = @driver.find_elements(:class => "android.widget.EditText").first
      last_name_element = @driver.find_elements(:class => "android.widget.EditText").last
      first_name_element.send_keys(@first_name)
      last_name_element.send_keys(@last_name)
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    end

    def choose_dob
      @logger.debug "Choosing date of birth"
      wait_for { @driver.find_elements(:xpath => "//android.widget.NumberPicker[@class='android.widget.NumberPicker']").count > 0 }
      number_pickers = @driver.find_elements(:xpath => "//android.widget.NumberPicker[@class='android.widget.NumberPicker']")
      day = number_pickers.first.find_elements(:xpath => "//android.widget.Button[@class='android.widget.Button']")
      year = number_pickers.last.find_elements(:xpath => "//android.widget.Button[@class='android.widget.Button']")
      day.first.click
      rand(17..19).to_i.times do
        year.first.click
        sleep(0.3)
      end
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    end

    def choose_sex
      @logger.debug("Choosing gender")
      wait_for {@driver.find_elements(:xpath => "//*[@text='Female']").count > 0}
      @driver.find_elements(:xpath => "//*[@text='Female']").first.click
      # @logger.screenshot
      @driver.find_elements(:xpath => "//*[@text='Next']").first.click
    end


    def wait_for(timeout = 20)
      begin
        Selenium::WebDriver::Wait.new(timeout: timeout).until { yield }
      rescue Selenium::WebDriver::Error::TimeoutError
        return false
      end
    end

  end
end