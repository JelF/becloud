# frozen_string_literal: true

require 'faker'
require 'json'
require 'sequel/extensions/pg_array'
require 'sequel/extensions/pg_hstore'

module Becloud::RowObfuscation

  MAX_INTEGER         = 1_000_000
  DAYS_BACK_IN_TIME   = 4_000
  CHARACTER_COUNT     = 20
  DECIMAL_LEFT_DIGITS = 3

  class << self

    # TODO Nil values
    def obfuscate_row(row, metadata, foreign_keys)
      row.map do |column, value|
        next [column, value] if foreign_keys.include?(column)
        type = metadata[column][:db_type]

        if type.end_with?('[]')
          type = type.tr('[]', '')
          array = [obfuscate_value(type), obfuscate_value(type)]
          value = Sequel.pg_array(array, type)
        else
          value = obfuscate_value(type)
        end

        [column, value]
      end.to_h
    end

    private

    # TODO Support varchar with upper limit
    # TODO Support numeric with parameters
    def obfuscate_value(type)
      case type
      when 'integer'
        Faker::Number.between(0, MAX_INTEGER)
      when /numeric.*/
        Faker::Number.decimal(3)
      when /character varying.*/
        # TODO Replace with loren word once unique indices are supported
        Faker::Lorem.characters(CHARACTER_COUNT)
      when 'text'
        Faker::Lorem.sentence
      when 'timestamp without time zone'
        Faker::Time.between(DateTime.now - DAYS_BACK_IN_TIME, DateTime.now)
      when 'date'
        Faker::Date.backward(DAYS_BACK_IN_TIME)
      when 'inet'
        Faker::Internet.ip_v4_address
      when 'json', 'jsonb'
        { Faker::Lorem.word => Faker::Lorem.word }.to_json
      when 'boolean'
        [true, false].sample
      when 'hstore'
        Sequel.hstore(Faker::Lorem.word => Faker::Lorem.word)
      else
        raise "Unsupported column type: #{type}"
      end
    end
  end
end
