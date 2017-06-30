# frozen_string_literal: true

require 'faker'
require 'json'
require 'set'
require 'sequel/extensions/pg_array'
require 'sequel/extensions/pg_hstore'

class Becloud::RowObfuscator

  MAX_INTEGER         = 999_999
  DAYS_BACK_IN_TIME   = 4_000
  CHARACTER_COUNT     = 20
  DECIMAL_LEFT_DIGITS = 3
  NULL_CHANCE         = 0.1

  def initialize(metadata, foreign_keys, unique_indices, rules)
    @metadata                = metadata
    @foreign_keys            = foreign_keys
    @unique_indices          = unique_indices
    @rules                   = rules
    # TODO Only store value hashes
    @unique_generated_values = {}
  end

  # TODO Refactor
  # TODO Comments
  # TODO Generate unique values for obfuscation instead of storing previous unique values
  # TODO Use rules
  def obfuscate_row(row)
    new_row = {}

    unique_indices.each do |columns|
      # TODO Can loop forever
      loop do
        attributes = columns.map { |column| [column, obfuscate_column(column, row[column])] }.to_h
        next if unique_generated_values_for(columns).include?(attributes)

        # Nulls are considered unique in SQL, don't store them
        unique_generated_values_for(columns) << attributes unless attributes.values.include?(nil)
        new_row.merge!(attributes)
        break
      end
    end

    (row.keys - unique_indices.flatten).each do |column|
      new_row.merge!(column => obfuscate_column(column, row[column]))
    end

    new_row
  end

  private

  attr_reader :metadata
  attr_reader :foreign_keys
  attr_reader :unique_indices
  attr_reader :unique_generated_values
  attr_reader :rules

  def obfuscate_column(column, value)
    # TODO Foreign key set to be anonymized?
    return value if foreign_keys.include?(column)

    return if metadata[column][:allow_null] && rand < NULL_CHANCE

    type = metadata[column][:db_type]
    if type.end_with?('[]')
      type  = type.tr('[]', '')
      array = [obfuscate_value(type), obfuscate_value(type)]
      Sequel.pg_array(array, type)
    else
      obfuscate_value(type)
    end
  end

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
      Faker::Lorem.words(2).join(' ')
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

  def unique_generated_values_for(columns)
    unique_generated_values[columns] ||= Set.new
  end
end
