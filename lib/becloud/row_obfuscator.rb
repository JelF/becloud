# frozen_string_literal: true

require 'becloud/value_obfuscation'

obfuscators = File.join(File.dirname(__FILE__), 'value_obfuscation', '*.rb')
Dir[obfuscators].each { |obfuscator| require(obfuscator) }

class Becloud::RowObfuscator

  NULL_CHANCE = 0.1

  def self.obfuscator_for_type(type)
    @obfuscators       ||= {}
    @obfuscators[type] ||= begin
      constant = type.split(' ').map(&:capitalize).join
      const_get("::Becloud::ValueObfuscation::#{constant}", false)
    end
  end

  def initialize(metadata, unique_indices, rules)
    @metadata       = metadata
    @unique_indices = unique_indices
    @rules          = rules
  end

  def obfuscate_row(row)
    row.map { |column, value| [column, obfuscate_column(column, value)] }.to_h
  end

  private

  attr_reader :metadata
  attr_reader :unique_indices
  attr_reader :rules

  # TODO Support unique columns
  # TODO Support all postgres types
  def obfuscate_column(column, value)
    return value if rules[column] == :keep
    return if metadata[column][:allow_null] && rand < NULL_CHANCE

    type = metadata[column][:db_type]
    self.class.obfuscator_for_type(type).obfuscate
  end
end
