# frozen_string_literal: true

require 'sequel'

module Becloud::Sequel

  def self.connect(db_name)
    Sequel.connect(adapter: :postgresql, database: db_name) { |db| yield db }
  end
end
