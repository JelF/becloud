# frozen_string_literal: true

require 'becloud/config'
require 'becloud/sequel'
require 'becloud/target_preparation'

module Becloud::Obfuscation

  def self.obfuscate(config_path)
    config = Becloud::Config.load_config(config_path)
    source_db_name = config.source_db_name

    # TODO Support all source db connection params (host, username, password, etc...)
    Becloud::Sequel.connect(source_db_name) do |source_db|
      target_db_name = config.target_db_name

      Becloud::TargetPreparation.with_prepared_target(source_db_name, target_db_name) do |target_db|
        # TODO
      end
    end
  end
end
