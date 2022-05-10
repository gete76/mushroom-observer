# frozen_string_literal: true

class Name < AbstractModel
  require "arel-helpers"
  include ArelHelpers::ArelTable

  ALL_LIFEFORMS = %w[
    basidiolichen
    lichen
    lichen_ally
    lichenicolous
  ].freeze

  def self.all_lifeforms
    ALL_LIFEFORMS
  end

  # This will include "lichen", "lichenicolous" and "lichen-ally" -- the usual
  # set of taxa lichenologists are interested in.
  def is_lichen?
    lifeform.include?("lichen")
  end

  # This excludes "lichen" but includes "mushroom" (so that truly lichenized
  # basidiolichens with mushroom fruiting bodies are included).
  def not_lichen?
    lifeform.exclude?(" lichen ")
  end

  validate :validate_lifeform

  # Sorts and uniquifies the lifeform words, and complains about any that are
  # not recognized.  It adds an extra space before and after to ensure that it
  # is easy to search for entire words instead of just substrings.  That is,
  # one can do this:
  #
  #   lifeform.include(" word ")
  #
  # and be confident that it will not skip "word" at the beginning or end,
  # and will not match "compoundword".
  def validate_lifeform
    words = lifeform.to_s.split(" ").sort.uniq
    self.lifeform = words.any? ? " #{words.join(" ")} " : " "
    unknown_words = words - ALL_LIFEFORMS
    return unless unknown_words.any?

    unknown_words = unknown_words.map(&:inspect).join(", ")
    errors.add(:lifeform, :validate_invalid_lifeform.t(words: unknown_words))
  end

  # Add lifeform (one word only) to all children.
  def propagate_add_lifeform(lifeform)
    concat_str = "#{lifeform} "
    search_str = "% #{lifeform} %"
    name_ids = all_children.map(&:id)
    return unless name_ids.any?

    n = Name.arel_table
    Name.where(id: name_ids).
      where(n[:lifeform].does_not_match(search_str)).
      update_all("lifeform = #{(n[:lifeform] + concat_str).to_sql}")

    o = Observation.arel_table
    Observation.where(name_id: name_ids).
      where(o[:lifeform].does_not_match(search_str)).
      update_all("lifeform = #{(o[:lifeform] + concat_str).to_sql}")
  end

  # Remove lifeform (one word only) from all children.
  def propagate_remove_lifeform(lifeform)
    replace_str = " #{lifeform} "
    search_str  = "% #{lifeform} %"
    name_ids = all_children.map(&:id)
    return unless name_ids.any?

    n = Name.arel_table
    Name.where(id: name_ids).
      where(n[:lifeform].matches(search_str)).
      update_all(lifeform: n[:lifeform].replace(replace_str, " "))

    o = Observation.arel_table
    Observation.where(name_id: name_ids).
      where(o[:lifeform].matches(search_str)).
      update_all(lifeform: o[:lifeform].replace(replace_str, " "))
  end
end
