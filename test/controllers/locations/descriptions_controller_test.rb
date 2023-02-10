# frozen_string_literal: true

require("test_helper")
require("set")

module Locations
  class DescriptionsControllerTest < FunctionalTestCase
    include ObjectLinkHelper

    ##########################################################################
    #
    #    SHOW

    def test_show_location_description
      # happy path
      desc = location_descriptions(:albion_desc)
      login
      get(:show, params: { id: desc.id })
      assert_template("show")
      assert_template("show/_location_description")

      # Unhappy paths
      # Prove they flash an error and redirect to the appropriate page

      # description is private and belongs to a project
      desc = location_descriptions(:bolete_project_private_location_desc)
      get(:show, params: { id: desc.id })
      assert_flash_error
      assert_redirected_to(project_path(desc.project.id))

      # description is private, for a project, project doesn't exist
      # but project doesn't existb
      desc = location_descriptions(:non_ex_project_private_location_desc)
      get(:show, params: { id: desc.id })
      assert_flash_error
      assert_redirected_to(location_path(desc.location_id))

      # description is private, not for a project
      desc = location_descriptions(:user_private_location_desc)
      get(:show, params: { id: desc.id })
      assert_flash_error
      assert_redirected_to(location_path(desc.location_id))
    end

    ############################################################################
    #
    #    INDEX

    def test_index_default_sort_order
      login
      get(:index)

      assert_select("#title", text: "Location Descriptions by Name")
    end

    def test_index_sorted_by_user
      login
      get(:index, params: { by: "user" })

      assert_select("#title", text: "Location Descriptions by User")
    end

    def test_index_with_id
      desc = location_descriptions(:albion_desc)

      login
      get(:index, params: { id: desc.id })

      assert_template(:index)
      assert_select("#title", text: "Location Description Index")
    end

    def test_index_list_all
      skip("Test is slow, incomplete, and almost useless as written.")

      login("mary")
      burbank = locations(:burbank)
      burbank.description = LocationDescription.create!(
        location_id: burbank.id,
        source_type: "public"
      )
      get(:index)
      assert_template("index")
    end

    def test_index_by_author_of_one_description
      desc = location_descriptions(:albion_desc)
      user = users(:rolf)
      assert_equal(
        1,
        LocationDescription.joins(:authors).where(user: user).count,
        "Test needs a user who authored exactly one description"
      )

      login
      get(:index, params: { by_author: "controller ignores this value",
                            id: user })

      assert_redirected_to(/#{location_description_path(desc)}/)
    end

    def test_index_by_author_of_multiple_descriptions
      user = users(:dick)
      descs_authored_by_user_count = \
        LocationDescription.joins(:authors).where(user: user).count
      assert_operator(
        descs_authored_by_user_count, :>, 1,
        "Test needs a user who authored multiple descriptions"
      )

      login
      get(:index, params: { by_author: "controller ignores this value",
                            id: user })

      assert_template("index")
      assert_select("#title",
                    text: "Location Descriptions Authored by #{user.name}")
      assert_equal(
        assert_select("#results").children.count,
        LocationDescription.joins(:authors).where(user: user).count
      )
      assert_select("a:match('href',?)", %r{^/locations/descriptions/\d+},
                    { count: descs_authored_by_user_count },
                    "Wrong number of results")
    end

    def test_index_by_author_of_no_descriptions
      user = users(:zero_user)

      login
      get(:index, params: { by_author: nil,
                            id: user })

      assert_template("index")
      assert_select("#title", text: "Location Description Index")
      assert_select("a:match('href',?)", %r{^/locations/descriptions/\d+},
                    { count: LocationDescription.count },
                    "Wrong number of results")
    end

    def test_index_by_editor
      login
      get(:index, params: { by_editor: "controller ignores value",
                            id: rolf.id })

      assert_template("index")
    end

    ############################################################################
    #
    #    NEW

    def test_create_location_description
      loc = locations(:albion)
      requires_login(:new, id: loc.id)
      assert_form_action(action: :create, id: loc.id)
    end

    def test_create_and_save_location_description
      loc = locations(:nybg_location) # use a location that has no description
      assert_nil(loc.description,
                 "Test should use a location that has no description.")
      params = { description: { source_type: "public",
                                source_name: "",
                                project_id: "",
                                public_write: "1",
                                public: "1",
                                license_id: "3",
                                gen_desc: "nifty botanical garden",
                                ecology: "varied",
                                species: "all",
                                notes: "FunDiS participant",
                                refs: "" },
                 id: loc.id }

      post_requires_login(:create, params)

      assert_redirected_to(location_description_path(loc.descriptions.last.id))
      assert_not_empty(loc.descriptions)
      assert_equal(params[:description][:notes], loc.descriptions.last.notes)
    end

    def test_unsuccessful_create_location_description
      loc = locations(:albion)
      user = login(users(:spammer).name)
      assert_false(user.successful_contributor?)
      get(:new, params: { id: loc.id })
      assert_response(:redirect)
    end

    ############################################################################
    #
    #    EDIT

    def test_edit_location_description
      desc = location_descriptions(:albion_desc)
      requires_login(:edit, { id: desc.id })
      assert_form_action(action: :update, id: desc.id)
    end

    def test_edit_and_save_location_description
      loc = locations(:albion) # use a location that has no description
      assert_not_nil(loc.description,
                     "Test should use a location that has a description.")
      params = { description: { source_type: "public",
                                source_name: "",
                                project_id: "",
                                public_write: "1",
                                public: "1",
                                license_id: licenses(:ccwiki30).id.to_s,
                                gen_desc: "research station",
                                ecology: "redwood",
                                species: "redwood zone",
                                notes: "church camp",
                                refs: "" },
                 id: location_descriptions(:albion_desc).id }

      put_requires_login(:update, params)

      assert_redirected_to(location_description_path(loc.descriptions.last.id))
      assert_not_empty(loc.descriptions)
      assert_equal(params[:description][:notes], loc.descriptions.last.notes)
    end
  end
end
