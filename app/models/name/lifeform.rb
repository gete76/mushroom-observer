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
  # Nimmo note: Are we sure the Name.update_all below is covered in tests?
  # I'm trying to remove the use of the update_all string interpolation syntax.
  # More notes below. Note that propagate_remove_lifeform does not need it.
  #
  def propagate_add_lifeform(lifeform)
    concat_str = "#{lifeform} "
    search_str = "% #{lifeform} %"
    name_ids = all_children.map(&:id)
    return unless name_ids.any?

    # These pass tests but i'm not sure they're tested:
    # update_all(lifeform: Name[:lifeform] + concat_str)
    # update_all(lifeform: Name[:lifeform].concat(concat_str))
    # So i'm using string interpolation as seems to be necessary below
    Name.where(id: name_ids).
      where(Name[:lifeform].does_not_match(search_str)).
      update_all("lifeform = #{(Name[:lifeform] + concat_str).to_sql}")

    # Likewise, I believe the following two should work but don't:
    # update_all(lifeform: Observation[:lifeform] + concat_str)
    # update_all(lifeform: Observation[:lifeform].concat(concat_str))
    # Weirdly this block seems to require a string interpolation in update_all.
    Observation.where(name_id: name_ids).
      where(Observation[:lifeform].does_not_match(search_str)).
      update_all("lifeform = #{(Observation[:lifeform] + concat_str).to_sql}")
  end

  # Remove lifeform (one word only) from all children.
  def propagate_remove_lifeform(lifeform)
    replace_str = " #{lifeform} "
    search_str  = "% #{lifeform} %"
    name_ids = all_children.map(&:id)
    return unless name_ids.any?

    Name.where(id: name_ids).
      where(Name[:lifeform].matches(search_str)).
      update_all(lifeform: Name[:lifeform].replace(replace_str, " "))

    Observation.where(name_id: name_ids).
      where(Observation[:lifeform].matches(search_str)).
      update_all(lifeform: Observation[:lifeform].replace(replace_str, " "))
  end
end
