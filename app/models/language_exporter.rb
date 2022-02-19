# frozen_string_literal: true

#
#  = Language Localization and Export Files
#
#  Translation strings (also called "localization strings" in places) are
#  exported to two types of files:
#
#  === Localization files
#
#  YAML files: <tt>config/locales/en.yml</tt>
#  These are written automatically and should never be edited by hand anymore.
#
#  === Export files
#
#  Text files: <tt>config/locales/en.yml</tt>
#  These are meant to be edited by hand.
#  Note that one of the locales is chosen as the "official" locale.  All the
#  other files are patterned after this one.  You can import changes from any
#  of these files, and it will update the database and YAML files automatically.
#
################################################################################

module LanguageExporter
  require "extensions"
  require "fileutils"

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :verbose, :safe_mode
    attr_reader :locales_path

    # Tried the following, but it ends up with nil in locales_dir
    # @locales_path = "config/locales"

    def locales_dir
      @locales_path = "config/locales" if @locales_path.nil?
      "#{::Rails.root}/#{@locales_path}"
    end

    def locales_path=(path)
      @locales_path = path
      FileUtils.mkdir_p(locales_dir) unless File.directory?(locales_dir)
      File.open("#{locales_dir}/en.txt", "a").close
    end

    def alt_locales_path(path, &block)
      old_path = locales_path
      Language.locales_path = path
      yield(block)
    ensure
      Language.locales_path = old_path
    end
  end

  def verbose(msg)
    puts(msg) if Language.verbose
  end

  def safe_mode
    Language.safe_mode
  end

  # This is the file used by Globalite; DO NOT EDIT THIS FILE!
  def localization_file
    "#{Language.locales_dir}/#{locale}.yml"
  end

  # This is the hand-editable export file.
  def export_file
    "#{Language.locales_dir}/#{locale}.txt"
  end

  # Update the YAML file used by Globalite.
  def update_localization_file
    write_localization_file(localization_strings)
  end

  # Update the editable export file.
  def update_export_file
    lines = format_export_file(localization_strings, translated_strings)
    write_export_file_lines(lines)
  end

  # Check syntax of export file.
  def check_export_syntax
    check_export_file_for_duplicates
    check_export_file_for_obvious_errors
    check_export_file_data
  end

  # Import changes from export file.
  def import_from_file
    any_changes = false
    unless old_user = User.current
      raise("Must specify a user to import translation file!") unless official

      User.current = User.admin
    end
    old_data = localization_strings
    new_data = read_export_file
    good_tags = Language.official.read_export_file
    tag_lookup = translation_strings_hash
    new_data.each do |tag, new_val|
      next unless new_val.is_a?(String) && good_tags.key?(tag)

      new_val = clean_string(new_val)
      old_val = clean_string(old_data[tag])
      next unless old_data[tag].nil? || (old_val != new_val)

      if (str = tag_lookup[tag])
        update_string(str, new_val, old_val)
      else
        create_string(tag, new_val, old_val)
      end
      any_changes = true
    end
    User.current = old_user
    any_changes
  end

  # Strip tags "unused" translation strings from unofficial locales.
  # That is, remove any strings from unofficial locales which are not also
  # in the official locale.
  def strip
    any_changes = false
    good_tags = Language.official.read_export_file
    for str in translation_strings.reject { |str| good_tags.key?(str.tag) }
      verbose("  deleting :#{str.tag}")
      translation_strings.delete(str) unless safe_mode
      any_changes = true
    end
    any_changes
  end

  # Return Hash mapping tag (String) to value (String), include official string
  # wherever translations are missing.
  def localization_strings
    if official
      merge_localization_strings_into({})
    else
      data = Language.official.localization_strings
      merge_localization_strings_into(data)
    end
  end

  # Return Hash mapping tag (String) to value (String), only include strings
  # which have been translated.
  def translated_strings
    merge_localization_strings_into({})
  end

  # Return Hash mapping tag (String) to
  # TranslationString (ActiveRecord instance).
  def translation_strings_hash
    hash = {}
    for str in translation_strings
      hash[str.tag] = str
    end
    hash
  end

  # Clean excess whitespace out of a string.
  def clean_string(val)
    val.to_s.gsub(/\\r|\r/, "").
      gsub(/\\n/, "\n").
      gsub(/[ \t]+\n/, "\n").
      gsub(/\n[ \t]+/, "\n").
      sub(/\A\s+/, "").
      sub(/\s+\Z/, "")
  end

  def read_localization_file
    File.open(localization_file, "r:utf-8") do |fh|
      YAML.load(fh)[locale][MO.locale_namespace]
    end
  end

  def write_localization_file(data)
    temp_file = localization_file + "." + Process.pid.to_s
    File.open(temp_file, "w:utf-8") do |fh|
      fh << { locale => { MO.locale_namespace => data } }.to_yaml
    end
    File.rename(temp_file, localization_file)
  end

  def read_export_file
    File.open(export_file, "r:utf-8") do |fh|
      YAML.load(fh)
    end
  end

  def read_export_file_lines
    File.open(export_file, "r:utf-8").readlines
  end

  def write_export_file_lines(output_lines)
    temp_file = export_file + "." + Process.pid.to_s
    File.open(temp_file, "w:utf-8") do |fh|
      for line in output_lines
        fh.write(line)
      end
    end
    File.rename(temp_file, export_file)
  end

  def write_hash(hash)
    write_export_file_lines(hash.map { |k, v| "  #{k}: #{format_string(v)}" })
  end

  ##############################################################################

  private

  def merge_localization_strings_into(data)
    for str in translation_strings
      data[str.tag] = str.text
    end
    data
  end

  def create_string(tag, new_val, _old_val)
    # verbose("  adding :#{tag}")
    # verbose("    was #{old_val.inspect}")
    # verbose("    now #{new_val.inspect}")
    return if safe_mode

    translation_strings.create(
      tag: tag,
      text: new_val
    )
  end

  def update_string(str, new_val, _old_val)
    # verbose("  updating :#{str.tag}")
    # verbose("    was #{old_val.inspect}")
    # verbose("    now #{new_val.inspect}")
    return if safe_mode

    str.update(
      text: new_val
    )
  end

  # ----------------------------
  #  :section: Formatting
  # ----------------------------

  # Takes two Hash'es, one mapping tag to translated string, another containing
  # only those tags which have translations.
  def format_export_file(strings, translated)
    template_lines = Language.official.read_export_file_lines
    output_lines = []
    in_tag = false
    for line in template_lines
      if line =~ /^(\W+['"]?(\w+)['"]?:)/
        out = Regexp.last_match(1)
        tag = Regexp.last_match(2)
        out += translated.key?(tag) ? " " : "  "
        out += format_string(strings[tag])
        output_lines << out
        in_tag = true if / >\s*$/.match?(line)
      elsif in_tag
        in_tag = false unless /\S/.match?(line)
      else
        output_lines << line.sub(/\s+$/, "\n")
      end
    end
    output_lines
  end

  def format_string(val)
    val = clean_string(val)
    if /\\n|\n/.match?(val)
      val = format_multiline_string(escape_string(val))
    elsif /:(\s|$)| #/.match?(val) ||
          /^(no|yes)$/i.match?(val) ||
          (/^\W/.match?(val) && val[0].is_ascii_character?)
      val = escape_string(val)
    elsif val == ""
      val = '""'
    end
    val + "\n"
  end

  def format_multiline_string(val)
    val.gsub(/\n/, '\n')
  end

  def escape_string(val)
    %("#{val.gsub(/(["\\])/, '\\\\\\1')}")
  end

  # ----------------------------
  #  :section: Validation
  # ----------------------------

  def check_export_file_for_duplicates
    once = {}
    twice = {}
    pass = true
    for line in read_export_file_lines
      next unless line =~ /^ *['"]?(\w+)['"]?:/

      if once[Regexp.last_match(1)] && !twice[Regexp.last_match(1)]
        verbose("#{locale} #{Regexp.last_match(1)}: " \
                "tag appears more than once")
        twice[Regexp.last_match(1)] = true
        pass = false
      end
      once[Regexp.last_match(1)] = true
    end
    pass
  end

  def check_export_file_data
    pass = true
    data = read_export_file
    for tag, str in data
      unless tag.is_a?(String)
        verbose("#{locale} #{tag}: tag is a #{tag.class.name} " \
                "instead of a String")
        pass = false
      end
      unless str.is_a?(String)
        verbose("#{locale} #{tag}: value is a #{str.class.name} " \
                "instead of a String")
        pass = false
      end
      unless validate_square_brackets(str)
        verbose("#{locale} #{tag}: square brackets messed up: #{str.inspect}")
        pass = false
      end
    end
    pass
  end

  def check_export_file_for_obvious_errors
    @pass = true
    @in_tag = false
    @line_number = 0
    for line in read_export_file_lines
      @line_number += 1
      check_export_line(line)
    end
    @pass
  end

  def check_export_line(line)
    if line =~ /^( *)(['"]?(\w+)['"]?):/
      indent = Regexp.last_match(1)
      quoted_tag = Regexp.last_match(2)
      tag = Regexp.last_match(3)
      str = $'
      check_export_tag_def_line(quoted_tag, tag, str) \
        unless indent.empty? && (tag == locale) && (str.strip == "")
    elsif @in_tag
      check_export_multi_line(line)
    else
      check_export_other_line(line)
    end
  end

  def check_export_tag_def_line(quoted_tag, tag, str)
    if @in_tag
      verbose("#{locale} #{@line_number}: " \
              "didn't finish multi-line string for #{@in_tag}")
      @in_tag = false
      @pass = false
    end
    if (quoted_tag.start_with?("'") && !quoted_tag.end_with?("'")) ||
       (quoted_tag.start_with?('"') && !quoted_tag.end_with?('"')) ||
       (quoted_tag.match(/['"]$/) && !quoted_tag.match(/^['"]/))
      verbose("#{locale} #{@line_number}: " \
              "invalid tag quotes: #{quoted_tag.inspect}")
      @pass = false
    end
    if /^(yes|no)$/i.match?(quoted_tag)
      verbose("#{locale} #{@line_number}: " \
              "'yes' and 'no' must be quoted in YAML files")
      @pass = false
    elsif !validate_tag(tag)
      verbose("#{locale} #{@line_number}: invalid tag: #{tag.inspect}")
      @pass = false
    end
    str.strip!
    if str == ">"
      @in_tag = tag
    elsif str == ""
      verbose("#{locale} #{@line_number}: missing string")
      @pass = false
    elsif !validate_string(str)
      verbose("#{locale} #{@line_number}: invalid string: #{str.inspect}")
      @pass = false
    end
  end

  def check_export_multi_line(line)
    if !line.match(/\S/)
      @in_tag = false
    elsif !line.start_with?(" ")
      verbose("#{locale} #{@line_number}: " \
              "failed to indent multi-ine string for #{@in_tag}")
      @pass = false
    end
  end

  def check_export_other_line(line)
    if !line.match(/^( *)#/) &&
       !line.match(/^---\s*$/) &&
       line.match(/\S/)
      verbose("#{locale} #{@line_number}: " \
              "invalid syntax between tags: #{line.inspect}")
      @pass = false
    end
  end

  def validate_tag(str)
    str.match(/^\w+$/)
  end

  def validate_string(str)
    str = str.strip.squeeze(" ")
    pass = true
    if /^(yes|no)$/i.match?(str)
      pass = false
    elsif str.start_with?("'")
      pass = false unless /^'([^'\\]|\\.)*'$/.match?(str)
    elsif str.start_with?('"')
      pass = false unless /^"([^"\\]|\\.)*"$/.match?(str)
    elsif /:(\s|$)| #/.match?(str) ||
          (/^[^\w(]/.match?(str) && str[0].is_ascii_character?)
      pass = false
    end
    pass
  end

  def validate_square_brackets(value)
    value = value.to_s.dup
    pass = true

    while value =~ /\S/
      next if extracted_argument_valid?(value)

      pass = false
      break
    end

    pass
  end

  def extracted_argument_valid?(value)
    value.sub!(/^[^\[\]]+/, "") ||
      value.sub!(/^\[\[/, "") ||
      value.sub!(/^\]\]/, "") ||
      value.sub!(/^\[\w+\]/, "") ||
      value.sub!(/^\[:\w+(?:\(([^\[\]]+)\))?\]/, "") &&
        (!Regexp.last_match(1) ||
        validate_square_brackets_args(Regexp.last_match(1)))
  end

  def validate_square_brackets_args(args)
    pass = true
    args.split(",").each do |pair|
      next if /^ :?\w+ = (
            '.*' | ".*" | -?\d+(\.\d+)? | :\w+ | [a-z][a-z_]*\d*
          )$/x.match?(pair)

      pass = false
      break
    end
    pass
  end
end
