# frozen_string_literal: true

require 'faker'
require 'json'
require 'sequel/extensions/pg_array'
require 'sequel/extensions/pg_hstore'

class Becloud::RowObfuscator

  MAX_INTEGER         = 999_999
  DAYS_BACK_IN_TIME   = 4_000
  CHARACTER_COUNT     = 20
  DECIMAL_LEFT_DIGITS = 3
  NULL_CHANCE         = 0.1

  def initialize(metadata, foreign_keys, unique_indices)
    @metadata       = metadata
    @foreign_keys   = foreign_keys
    @unique_indices = unique_indices
  end

  # TODO Handle unique indices
  def obfuscate_row(row)
    row.map do |column, value|
      next [column, value] if foreign_keys.include?(column)
      next [column, nil] if metadata[column][:allow_null] && rand < NULL_CHANCE

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

  attr_reader :metadata
  attr_reader :foreign_keys
  attr_reader :unique_indices

  # TODO Support varchar with upper limit
  # TODO Support numeric with parameters
  # TODO Support all postgres types
  def obfuscate_value(type)
    case type
    when 'integer'
      Faker::Number.between(0, MAX_INTEGER)
    when /numeric.*/
      Faker::Number.decimal(3)
    when /character varying.*/
      # TODO Replace with lorem ipsum word once unique indices are supported
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
