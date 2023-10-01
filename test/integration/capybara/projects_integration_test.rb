# frozen_string_literal: true

require("test_helper")

# Test relating to projects
class ProjectsIntegrationTest < CapybaraIntegrationTestCase
  def test_add_project_dates
    login(mary)
    title = "Super Grandiloquent National Fungal Foray"

    # Add project, default dates
    visit(projects_path)
    click_on(:list_projects_add_project.l)
    fill_in(:form_projects_title.l, with: title)
    assert_difference("Observation.count", 1, "Failed to created Project" ) do
      click_on("Create")
    end

    project = Project.order(created_at: :asc).last
    assert_equal(title, project.title)
    assert_equal(Time.zone.today, project.start_date,
                 "Project Start Date should default to current date")
    assert_equal(Time.zone.today, project.start_date,
                 "Project Start Date should default to current date")
  end
end
