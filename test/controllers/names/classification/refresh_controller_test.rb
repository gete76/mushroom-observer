# frozen_string_literal: true

require("test_helper")
require("set")

module Names::Classification
  class RefreshControllerTest < FunctionalTestCase
    include ObjectLinkHelper

    def test_refresh_classification
      genus = names(:coprinus)
      child = names(:coprinus_comatus)
      val   = genus.classification
      time  = genus.updated_at
      assert_equal(val, child.classification)
      assert_equal(val, child.description.classification)
      assert_equal(time, child.updated_at)
      assert_equal(time, child.description.updated_at)

      # Make sure bogus requests don't crash.
      login("rolf")
      get(:refresh_classification)
      get(:refresh_classification, params: { id: 666 })
      get(:refresh_classification, params: { id: "bogus" })
      get(:refresh_classification, params: { id: genus.id })
      get(:refresh_classification, params: { id: child.id }) # no change!
      assert_equal(val, genus.reload.classification)
      assert_equal(val, genus.description.reload.classification)
      assert_equal(val, child.reload.classification)
      assert_equal(val, child.description.reload.classification)
      assert_equal(time, genus.updated_at)
      assert_equal(time, genus.description.updated_at)
      assert_equal(time, child.updated_at)
      assert_equal(time, child.description.updated_at)

      # Make sure have to be logged in. (update_column should avoid callbacks)
      new_val = names(:peltigera).classification
      # disable cop because we're trying to avoid callbacks
      child.update_columns(classification: new_val)
      child.description.update_columns(classification: new_val)
      logout
      get(:refresh_classification, params: { id: child.id })
      assert_equal(new_val, child.reload.classification)
      assert_equal(time, child.updated_at)

      # Now finally do it right and make sure it makes correct changes.
      login("rolf")
      get(:refresh_classification, params: { id: child.id })
      assert_equal(val, child.reload.classification)
      assert_not_equal(time, child.updated_at)
    end
  end
end
