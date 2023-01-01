# frozen_string_literal: true

require("test_helper")

module SpeciesLists
  class UploadsControllerTest < FunctionalTestCase
    # ----------------------------
    #  Upload files.
    # ----------------------------

    def test_upload_species_list
      spl = species_lists(:first_species_list)
      params = {
        id: spl.id
      }
      requires_user(:upload_species_list, :show, params)
      assert_form_action(action: "upload_species_list", id: spl.id)
    end

    def test_read_species_list
      # TODO: Test read_species_list with a file larger than 13K to see if it
      # gets a TempFile or a StringIO.
      spl = species_lists(:first_species_list)
      assert_equal(0, spl.observations.length)
      path = Rails.root.join("test/species_lists/small_list.txt")
      file = File.new(path)
      list_data = file.read.split(/\s*\n\s*/).compact_blank.join("\r\n")
      file = Rack::Test::UploadedFile.new(path, "text/plain")
      params = {
        "id" => spl.id,
        "species_list" => {
          "file" => file
        }
      }
      login("rolf", "testpassword")
      post(:upload_species_list, params: params)
      assert_edit_species_list
      assert_equal(10, rolf.reload.contribution)
      # Doesn't actually change list, just feeds it to edit_species_list
      assert_equal(list_data, @controller.instance_variable_get(:@list_members))
    end

    def test_read_species_list_two
      spl = species_lists(:first_species_list)
      assert_equal(0, spl.observations.length)
      path = Rails.root.join("test/species_lists/foray_notes.txt")
      file = File.new(path)
      list_data = file.read.split(/\s*\n\s*/).compact_blank.join("\r\n")
      file = Rack::Test::UploadedFile.new(path, "text/plain")
      params = {
        "id" => spl.id,
        "species_list" => {
          "file" => file
        }
      }
      login("rolf", "testpassword")
      post(:upload_species_list, params: params)
      assert_edit_species_list
      assert_equal(10, rolf.reload.contribution)
      new_data = @controller.instance_variable_get(:@list_members)
      new_data = new_data.split("\r\n").sort.join("\r\n")
      assert_equal(list_data, new_data)
    end
  end
end
