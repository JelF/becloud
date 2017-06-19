# frozen_string_literal: true

require 'becloud/config'

module Becloud::Obfuscation

  def self.obfuscate(config_path)
    config = Becloud::Config.load_config(config_path)
  end
end
