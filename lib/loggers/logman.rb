module Farmpage
  class Logger
    attr_accessor :lines
    attr_accessor :task
    attr_accessor :driver

    def initialize(task = nil, device)
      File.readlines("#{REAL_ROOT}/farmpage.logo").each do |line|
        print line.colorize(:light_blue)
      end
      puts ""
      @device = device
      @task = task
      @lines = ''
    end

    def noise(text, color = :yellow)
      puts "#{@device.nil? ? "General" : @device.udid}: #{text.colorize(color)}"
    end

    def critical(exception)
      puts "==================".colorize(:red)
      puts exception.class.to_s.colorize(:red)
      puts exception.message.colorize(:red)
      puts exception.backtrace.join("\t\n").colorize(:red)
      from_bot = Telegram::Bot::Api.new('1753275760:AAEcuKzcNVcbHRw8epLK-V5pV7TBJlfmMfc')
      ['972445859', '366525'].each do |cli|
        txt = "❌ `#{exception.class.to_s}`"
        from_bot.send_message(
          chat_id: cli,
          text: txt,
          parse_mode: :markdown
        )
      end
    end

    def say(text, color = :gray)
      @lines << text << "\n"
      puts "#{@device.nil? ? "General" : @device.udid}: #{text.colorize(color)}"
    end

    def _say(text, color = :gray)
      @lines << text
      puts "#{@device.nil? ? "General" : @device.udid}: #{text.colorize(color)}"
    end

    def answer(text, color = :green)
      @lines << text << "\n"
      puts "#{@device.nil? ? "General" : @device.udid}: #{text.colorize(color)}"
    end

    def record(text)
      con = Faraday.new
      con.post do |req|
        req.url "https://#{FARMPAGE}/api/task/#{@task}/progress"
        req.body = "message=#{text}"
      end
    end

    def screenshot(udid)
      screen_file = rand(1111111..9999999)
      filename = "#{ROOT}/screenshots/#{screen_file}.png"
      # sleep(0.3)
      system("adb -s #{udid} exec-out screencap -p > #{filename}")
      cloudfile = Cloudinary::Uploader.upload(filename, use_filename: true, unique_filename: true, :resource_type => "auto")
      picture_url = cloudfile['url']
      system("rm #{filename}")
     con = Faraday.new
      con.post do |req|
        req.url "https://#{FARMPAGE}/api/task/#{@task}/progress/screenshot"
        req.body = "screenshot=#{picture_url}"
      end
    end

    def log(message)
      self.record(message)
      self.noise message
      self.telegram message
    end
    
    def debug(message)
      # self.telegram message
      self.record(message)
      self.noise message
    end

    def telegram(message)
      from_bot = Telegram::Bot::Api.new('1753275760:AAEcuKzcNVcbHRw8epLK-V5pV7TBJlfmMfc')
      ['972445859', '366525', '1518566808', '1718870696'].each do |cli|
        from_bot.send_message(
          chat_id: cli,
          text: message,
          parse_mode: :markdown
        )
      end
    end

  end
end
