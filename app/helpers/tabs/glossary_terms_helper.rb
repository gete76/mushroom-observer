# frozen_string_literal: true

module Tabs
  module GlossaryTermsHelper
    def glossary_term_show_links(term:, user:)
      return [] unless user

      links = [
        glossary_terms_index_link,
        new_glossary_term_link,
        edit_glossary_term_link(term)
      ]
      links << destroy_glossary_term_link(term) if in_admin_mode?
      links
    end

    def glossary_term_index_links
      [new_glossary_term_link]
    end

    def glossary_term_form_new_links
      [
        # Replace this link with a "Cancel" link (back to glossary)
        # See https://www.pivotaltracker.com/story/show/174614188
        glossary_terms_index_link
      ]
    end

    def glossary_term_form_edit_links(term:)
      [
        # Replace these two links with a "Cancel" link
        # See https://www.pivotaltracker.com/story/show/174614188
        glossary_term_return_link(term),
        glossary_terms_index_link
      ]
    end

    def glossary_term_image_form_links(term:)
      [
        glossary_term_return_link(term),
        edit_glossary_term_link(term)
      ]
    end

    def glossary_term_version_links(term:)
      [show_glossary_term_link(term)]
    end

    def show_glossary_term_link(term)
      [:show_glossary_term.t(glossary_term: term.name),
       glossary_term_path(term.id),
       { class: __method__.to_s }]
    end

    def glossary_term_return_link(term)
      [:cancel_and_show.t(type: :glossary_term),
       glossary_term_path(term.id),
       { class: __method__.to_s }]
    end

    def destroy_glossary_term_link(term)
      [nil, term, { button: :destroy }]
    end

    def glossary_terms_index_link
      [:glossary_term_index.t, glossary_terms_path,
       { class: __method__.to_s }]
    end

    def new_glossary_term_link
      [:create_glossary_term.t, new_glossary_term_path,
       { class: __method__.to_s }]
    end

    def edit_glossary_term_link(term)
      [:edit_glossary_term.t, edit_glossary_term_path(term.id),
       { class: __method__.to_s }]
    end
  end
end