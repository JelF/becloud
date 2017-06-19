# frozen_string_literal: true

require 'sequel'
require 'becloud/config'

module Becloud::Obfuscation

  def self.obfuscate(config_path)
    config = Becloud::Config.load_config(config_path)

    Sequel.connect(config.source) do |source|
      Sequel.connect(config.target) do |target|
        require 'pry'; binding.pry
      end
    end
  end
end
