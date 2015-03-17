require 'rails'
require 'rollbar'

APP_PATH = File.expand_path('config/application', Dir.pwd)

module Rollbar
  class RailsRunner
    def run
      prepare_environment

      rollbar_managed { eval_runner }
    end

    def prepare_environment
      require File.expand_path('../environment', APP_PATH)
      ::Rails.application.require_environment!
    end

    def eval_runner
      string_to_eval = File.read(runner_path)

      Module.module_eval(<<-EOL,__FILE__,__LINE__ + 2)
          #{string_to_eval}
        EOL
    end

    def rollbar_managed
      yield
    rescue => e
      Rollbar.error(e)
      raise
    end

    def runner_path
      railties_gem_dir + '/lib/rails/commands/runner.rb'
    end

    def railties_gem
      gem = Gem::Specification.find_by_name('railties')
      abort 'railties gem not found' unless gem

      gem
    end

    def railties_gem_dir
      railties_gem.gem_dir
    end
  end
end


