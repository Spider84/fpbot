module Farmpage
  class PrepareLogger < Farmpage::Logger

    def initialize(task = nil)
      @lines = ''
      @device = nil
    end

  end
end
