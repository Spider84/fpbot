module Farmpage
  class Processor
    attr_accessor :task

    def initialize(task = nil, logger, device_id, host, port, appium_port, task_num)
      raise Farmpage::Exceptions::NoTask.new("Response from api: #{task.to_s}. There is no `command` attribute in /api/task response.") if task['command'].nil?
      @task = task
      @device_id = device_id
      @host = host
      @port = port
      @platform = task['platform']
      @command = task['command']
      @avd = task['avd']
      @proxy = "#{task['proxy']['login']}:#{task['proxy']['password']}@#{task['proxy']['host']}:#{task['proxy']['port']}"
      @logger = logger
      @appium_port = appium_port
      @task_num = task_num
    end

    def process!
      platform_processor = "Farmpage::Facebook".constantize.new(@task, @avd, @proxy, @logger, @device_id, @host, @port, @appium_port, @task_num)
      platform_processor.public_send(@command)
    end

  end
end
