module Farmpage
  module Exceptions

    class NoTask < Exception
    end

    class NoSMSnumbers < Exception
    end

    class SMSTimeout < Exception
    end

    class NoEmulatorsToCreate < Exception
    end

    class Banned < Exception
    end

    class BadProxy < Exception
    end

    class CouldNotLaunchEmulator < Exception
    end

  end
end