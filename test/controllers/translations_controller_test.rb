# frozen_string_literal: true

require("test_helper")

class TranslationsControllerTest < FunctionalTestCase
  def mock_template
    [
      "---\n",
      " garbage \n",
      "##################################\n",
      "\n",
      "# IMPORTANT STUFF\n",
      "\n",
      "# Main Objects:\n",
      "image: image\n",
      "name: name\n",
      "user: user\n",
      "\n",
      "# Actions:\n",
      "prev: Prev\n",
      "# ignore this comment\n",
      "next: Next\n",
      "index: Index\n",
      "show_object: Show [type]\n",
      "\n",
      "##################################\n",
      "\n",
      "# MAIN PAGES\n",
      "\n",
      "# observations/index\n",
      "index_title: Main Index\n",
      "# you don't see this every day\n",
      "index_error: An unusual error occurred\n",
      "index_help: >\n",
      "  This page shows an index of objects.\n",
      "\n",
      "index_prefs: Your Account\n",
      "\n",
      "# account/prefs\n",
      "prefs_title: Your Account\n",
      "\n"
    ].join
  end

  def hashify(*args)
    args.index_with { |_arg| true }
  end

  def assert_major_header(str, item)
    assert(item.is_a?(TranslationController::TranslationFormMajorHeader))
    assert_equal(str, item.string)
  end

  def assert_minor_header(str, item)
    assert(item.is_a?(TranslationController::TranslationFormMinorHeader))
    assert_equal(str, item.string)
  end

  def assert_comment(str, item)
    assert(item.is_a?(TranslationController::TranslationFormComment))
    assert_equal(str, item.string)
  end

  def assert_tag_field(tag, item)
    assert(item.is_a?(TranslationController::TranslationFormTagField))
    assert_equal(tag, item.tag)
  end

  ##############################################################################

  def test_index_with_page
    Language.track_usage
    :name.l
    assert_equal(["name"], Language.tags_used)
    page = Language.save_tags
    get(:index, params: { for_page: page })
  end

  def test_primary_tag
    lang = languages(:english)
    strings = lang.localization_strings
    assert(strings.length >= 8)
    assert_equal("one", @controller.primary_tag("one", strings))
    assert_equal("two", @controller.primary_tag("two", strings))
    assert_equal("two", @controller.primary_tag("Two", strings))
    assert_equal("two", @controller.primary_tag("TWOS", strings))
    assert_equal("two", @controller.primary_tag("tWoS", strings))
    assert_equal("four", @controller.primary_tag("FoUr", strings))
  end

  def test_build_form
    lang = languages(:english)
    file = mock_template

    form = @controller.build_form(lang, hashify, file)
    assert_equal([], form)

    form = @controller.build_form(lang, hashify("name"), file)
    assert_major_header("IMPORTANT STUFF", form.shift)
    assert_minor_header("Main Objects:", form.shift)
    assert_tag_field("name", form.shift)
    assert(form.empty?)

    form = @controller.build_form(lang, hashify("index", "index_help"), file)
    assert_major_header("IMPORTANT STUFF", form.shift)
    assert_minor_header("Actions:", form.shift)
    assert_tag_field("index", form.shift)
    assert_major_header("MAIN PAGES", form.shift)
    assert_minor_header("observations/index", form.shift)
    assert_tag_field("index_title", form.shift)
    assert_comment("you don't see this every day", form.shift)
    assert_tag_field("index_error", form.shift)
    assert_tag_field("index_help", form.shift)
    assert_tag_field("index_prefs", form.shift)
    assert(form.empty?)
  end

  def test_authorization_no_login_en
    get(:index, params: { locale: "en" })
    assert_response(:redirect)
  end

  def test_authorization_no_login_el
    get(:index, params: { locale: "el" })
    assert_response(:redirect)
  end

  def test_authorization_user_en
    login("mary")
    get(:index, params: { locale: "en" })
    assert_flash_error
    assert_response(:redirect)
  end

  def test_authorization_zero_user
    login("zero_user")
    get(:index, params: { locale: "en" })
    assert_flash_error
    assert_response(:redirect)
  end

  def test_authorization_user_bad_locale
    login("mary")
    get(:index, params: { locale: "bad" })
    assert_flash_error
    assert_response(:redirect)
  end

  def test_authorization_user_el
    login("mary")
    get(:index, params: { locale: "el" })
    assert_no_flash
    assert_response(:success)
  end

  def test_authorization_admin_en
    login("rolf")
    get(:index, params: { locale: "en" })
    assert_no_flash
    assert_response(:success)
  end

  def test_edit
    login("rolf")
    get(:index)
    assert_no_flash
    assert_response(:success, locale: "en")
    assert_select("input[type=submit][value=#{:SAVE.l}]", 0)
  end

  def test_edit_tag
    login("rolf")
    get(:edit, params: { locale: "en", tag: "xxx" })
    assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
    assert_select("textarea[name=tag_xxx]", 1)
    assert_textarea_value(:tag_xxx, "")
  end

  def test_edit_tag_two
    login("rolf")
    get(:edit, params: { locale: "en", tag: "two" })
    assert_no_flash
    assert_response(:success)
    assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
    assert_select("textarea[name=tag_two]", 1)
    assert_select("textarea[name=tag_twos]", 1)
    assert_select("textarea[name=tag_TWO]", 1)
    assert_select("textarea[name=tag_TWOS]", 1)
    assert_textarea_value(:tag_two, "two")
    assert_textarea_value(:tag_twos, "twos")
    assert_textarea_value(:tag_TWO, "Two")
    assert_textarea_value(:tag_TWOS, "Twos")
  end

  def translation_for_one(locale, value, _commit = :SAVE.l)
    patch(:update, params: {
            locale: locale, tag: "one", tag_one: value, commit: :SAVE.l
          })
  end

  def test_update_save_z
    use_test_locales do
      login("rolf")
      old_one = :one.l
      translation_for_one("en", "uno")
      assert_flash_success
      assert_equal("uno", :one.l)
      assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
      assert_select("textarea[name=tag_one]", 1)
      assert_textarea_value(:tag_one, "uno")
      translation_for_one("en", old_one)
    end
  end

  def test_update_cancel
    login("rolf")
    old_one = :one.l
    translation_for_one("en", "ichi", :CANCEL.l)
    # patch(:update,
    #       params: {
    #         locale: "en", tag: "one", tag_one: "ichi", commit: :CANCEL.l
    #       })
    assert_no_flash
    assert_equal(old_one, :one.l)
    assert_select("input[type=submit][value=#{:SAVE.l}]", 0)
  end

  def test_update_reload_greek
    login("rolf")
    old_one = :one.l
    translation_for_one("en", "ichi", :RELOAD.l)
    # patch(:update,
    #       params: {
    #         locale: "el", tag: "one", tag_one: "ichi", commit: :RELOAD.l
    #       })
    assert_no_flash
    assert_equal(old_one, :one.l)
    assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
    assert_textarea_value(:tag_one, "ένα")
  end

  def test_update_save_greek
    use_test_locales do
      initial_locale = I18n.locale
      I18n.with_locale(:el) do
        greek_one = :one.l
        I18n.with_locale(initial_locale) do
          login("rolf")
          translation_for_one("el", "ichi")
          assert_flash_success
          assert_equal("one", :one.l)
          assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
          assert_textarea_value(:tag_one, "ichi")
        end
        assert_equal("ichi", :one.l)
        translation_for_one("el", greek_one)
      end
    end
  end

  # Moved to translations system test. Functions differently
  # def test_edit_translation_ajax_form
  #   use_test_locales do
  #     old_one = :one.l
  #     initial_locale = I18n.locale
  #     I18n.with_locale(:el) do
  #       greek_one = :one.l
  #       I18n.with_locale(initial_locale) do
  #         login("rolf")
  #         get(:edit, params: { locale: "en", tag: "two" })
  #         assert_no_flash
  #         assert_response(:success)
  #         assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
  #         assert_select("textarea[name=tag_two]", 1)
  #         assert_select("textarea[name=tag_twos]", 1)
  #         assert_select("textarea[name=tag_TWO]", 1)
  #         assert_select("textarea[name=tag_TWOS]", 1)
  #         assert_textarea_value(:tag_two, "two")
  #         assert_textarea_value(:tag_twos, "twos")
  #         assert_textarea_value(:tag_TWO, "Two")
  #         assert_textarea_value(:tag_TWOS, "Twos")

  #         assert_equal(old_one, :one.l)
  #         old_one = :one.l
  #         translation_for_one("en", "uno")
  #         assert_no_flash
  #         assert_match(/locale = "en"/, @response.body)
  #         assert_match(/tag = "one"/, @response.body)
  #         assert_match(/str = "uno"/, @response.body)
  #         assert_equal("uno", :one.l)

  #         get(:edit, params: { locale: "en", tag: "one" })
  #         assert_no_flash
  #         assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
  #         assert_select("textarea[name=tag_one]", 1)
  #         assert_textarea_value(:tag_one, "uno")
  #         translation_for_one("en", old_one)

  #         translation_for_one("el", "ichi")
  #         assert_no_flash
  #         assert_match(/locale = "el"/, @response.body)
  #         assert_match(/tag = "one"/, @response.body)
  #         assert_match(/str = "ichi"/, @response.body)
  #         assert_equal("one", :one.l)

  #         get(:edit, params: { locale: "el", tag: "one" })
  #         assert_no_flash
  #         assert_select("input[type=submit][value=#{:SAVE.l}]", 1)
  #         assert_textarea_value(:tag_one, "ichi")
  #       end
  #       assert_equal("ichi", :one.l)
  #       translation_for_one("el", greek_one)
  #     end
  #   end
  # end

  def test_page_expired
    login("rolf")
    make_admin

    Language.track_usage
    :all.l
    :none.l
    page = Language.save_tags

    # Page is good, should only display the two tags used above.
    get(:index, params: { locale: "en", for_page: page })
    assert_no_flash
    assert_equal(2, assigns(:show_tags).length)

    # Simulate page expiration:
    # result is it will display all tags, not just the two used above.
    get(:index, params: { locale: "en", for_page: "xxx" })
    assert_flash_error
    assert(assigns(:show_tags).length > 2)
  end
end
