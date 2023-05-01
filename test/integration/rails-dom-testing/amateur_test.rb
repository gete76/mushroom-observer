# frozen_string_literal: true

require("test_helper")

# Test typical sessions of amateur user who just posts the occasional comment,
# observations, or votes.
class AmateurTest < IntegrationTestCase
  # ----------------------------
  #  Test autologin cookies.
  # ----------------------------

  def test_autologin
    rolf_cookies = get_cookies(rolf, true)
    mary_cookies = get_cookies(mary, true)
    dick_cookies = get_cookies(dick, false)
    try_autologin(rolf_cookies, rolf)
    try_autologin(mary_cookies, mary)
    try_autologin(dick_cookies, false)
  end

  def get_cookies(user, autologin)
    sess = open_session
    sess.login(user, "testpassword", autologin)
    result = sess.cookies.dup
    if autologin
      assert_match(/^#{user.id}/, result["mo_user"])
    else
      assert_equal("", result["mo_user"].to_s)
    end
    result
  end

  def try_autologin(cookies, user)
    sess = open_session
    sess.cookies["mo_user"] = cookies["mo_user"]
    sess.get("/account/preferences/edit")
    if user
      sess.assert_match("account/preferences/edit", sess.response.body)
      sess.assert_no_match("account/login/new", sess.response.body)
      assert_users_equal(user, sess.assigns(:user))
    else
      sess.assert_no_match("account/preferences/edit", sess.response.body)
      sess.assert_match("account/login/new", sess.response.body)
    end
  end


  # ------------------------------------------------------------------------
  #  Quick test to try to catch a bug that the functional tests can't seem
  #  to catch.  (Functional tests can survive undefined local variables in
  #  partials, but not integration tests.)
  # ------------------------------------------------------------------------

  def test_edit_image
    login("mary")
    get("/images/1/edit")
  end

  # ------------------------------------------------------------------------
  #  Tests to make sure that the proper links are rendered  on the  home page
  #  when a user is logged in.
  #  test_user_dropdown_avaiable:: tests for existence of dropdown bar & links
  #
  # ------------------------------------------------------------------------

  def test_user_dropdown_avaiable
    login("dick")
    get("/")
    assert_select("li#user_drop_down")
    links = css_select("li#user_drop_down a")
    assert_equal(links.length, 7)
  end

  # -------------------------------------------------------------------------
  #  Need integration test to make sure session and actions are all working
  #  together correctly.
  # -------------------------------------------------------------------------

  def test_thumbnail_maps
    get("/#{observations(:minimal_unknown_obs).id}")
    assert_template("observations/show")

    login("dick")
    assert_template("observations/show")
    assert_select("div.thumbnail-map", 1)
    click_mo_link(label: "Hide thumbnail map")
    assert_template("observations/show")
    assert_select("div.thumbnail-map", 0)

    get("/#{observations(:detailed_unknown_obs).id}")
    assert_template("observations/show")
    assert_select("div.thumbnail-map", 0)
  end

  # -----------------------------------------------------------------------
  #  Need intrgration test to make sure tags are being tracked and passed
  #  through redirects correctly.
  # -----------------------------------------------------------------------

  def test_language_tracking
    session = open_session.extend(UserDsl)
    session.login(mary)
    mary.locale = "el"
    I18n.with_locale(:el) do
      mary.save

      TranslationString.store_localizations(
        :el,
        { test_tag1: "test_tag1 value",
          test_tag2: "test_tag2 value",
          test_flash_redirection_title: "Testing Flash Redirection" }
      )

      session.run_test
    end
  end

  module UserDsl
    def run_test
      get("/test_pages/flash_redirection?tags=")
      click_mo_link(label: :app_edit_translations_on_page.t)
      assert_no_flash
      assert_select("span.tag", text: "test_tag1:", count: 0)
      assert_select("span.tag", text: "test_tag2:", count: 0)
      assert_select("span.tag", text: "test_flash_redirection_title:", count: 1)

      get("/test_pages/flash_redirection?tags=test_tag1,test_tag2")
      click_mo_link(label: :app_edit_translations_on_page.t)
      assert_no_flash
      assert_select("span.tag", text: "test_tag1:", count: 1)
      assert_select("span.tag", text: "test_tag2:", count: 1)
      assert_select("span.tag", text: "test_flash_redirection_title:", count: 1)
    end
  end

end
