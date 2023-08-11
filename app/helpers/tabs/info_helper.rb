# frozen_string_literal: true

module Tabs
  module InfoHelper
    def info_site_stats_links
      [
        [:app_contributors.t, contributors_path,
         { class: "contributors_link" }],
        [:site_stats_observed_taxa.t, checklist_path,
         { class: "checklist_link" }]
      ]
    end
  end
end
