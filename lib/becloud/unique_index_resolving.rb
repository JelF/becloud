module Becloud::UniqueIndexResolving

  class << self

    def resolve_indices(db, table)
      indices = db.indexes(table).values.select { |index| index[:unique] }
      normalize_indices(indices.map { |index| index[:columns] })
    end

    private

    def normalize_indices(indices)
      return [] if indices.empty?
      current_index = indices.first
      rest = indices[1, indices.length]

      if rest.find { |index| same_index?(current_index, index) }
        return normalize_indices(rest)
      end

      overlapping_index = rest.find { |index| indices_have_overlaps?(current_index, index) }
      return [current_index] + normalize_indices(rest) unless overlapping_index

      if overlapping_index.find { |column| current_index.include?(column) }
        overlap = current_index & overlapping_index
        normalize_indices([overlap] + rest.reject { |index| same_index?(overlapping_index, index) })
      else
        normalize_indices(rest)
      end
    end

    def same_index?(index_1, index_2)
      index_1.sort == index_2.sort
    end

    def indices_have_overlaps?(index_1, index_2)
      index_1.find { |column| index_2.include?(column) }
    end
  end
end
