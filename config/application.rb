# frozen_string_literal: true

require_relative("boot")

# To load all of Rails:
# require("rails/rails")

# To choose what Rails frameworks to load, and skip others:
# NOTE: Be sure this list reflects the same choices made in the Gemfile
require("rails") # NOTE: not "rails/rails"
require("active_model/railtie")
require("active_job/railtie")
require("active_record/railtie")
# require("active_storage/engine")
require("action_controller/railtie")
require("action_mailer/railtie")
# require("action_mailbox/engine")
# require("action_text/engine")
require("action_view/railtie")
require("action_cable/engine")
require("sprockets/railtie")
require("rails/test_unit/railtie")

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MushroomObserver
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those
    # specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[
      #{config.root}/app/classes
      #{config.root}/app/extensions
    ]
    config.eager_load_paths += %W[
      #{config.root}/app/classes
      #{config.root}/app/extensions
    ]

    # Uncomment this after migrating to all recommended default configs for 7.1
    # config/initializers/new_framework_defaults_7_1.rb
    # config.load_defaults = 7.1

    # Set Time.zone default to the specified zone and
    # make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names.
    # Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from
    # config/locales/*.rb, yml are auto loaded.
    # config.i18n.load_path +=
    #  Dir[Rails.root.join("my", "locales", "*.{rb,yml}").to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Tells rails not to generate controller-specific css and js stubs.
    config.generators.assets = false

    # This instructs ActionView how to mark form fields which have an error.
    # I just change the CSS class to "has-error", which gives it a red border.
    # This is superior to the default, which encapsulates the field in a div,
    # because that throws the layout off.  Just changing the border, while less
    # conspicuous, has no effect on the layout.  This is not a hack, this is
    # just a standard configuration many rails apps take advantage of.
    # Note client side validation is not working as of 2023-02-01
    # For bootstrap 4 the class is "is-invalid"
    config.action_view.field_error_proc = proc { |html_tag, _instance|
      html_tag.gsub("form-control", "form-control has-error").html_safe
    }
    # Rails removed automatically generated input IDs in forms generated by
    # `form_with` in 5.1, but then restored them in 5.2. However, the
    # default does not seem to work on MO. This restores automatically
    # generated form input IDs in 6.1, as they were in `form_for`.
    config.action_view.form_with_generates_ids = true

    # Turbo supersedes the functionality offered by Rails UJS to turn links and
    # form submissions into XMLHttpRequests, so if you're making a complete
    # switch from Rails UJS to Turbo, you should ensure that you have this:
    config.action_view.form_with_generates_remote_forms = false
    # This is a UJS config that can be explicitly set
    # config.action_view.automatically_disable_submit_tag = false

    # Rails 6.1 can auto-generate HTML comments with the template filename
    # Unfortunately this is also added to email templates!
    # config.action_view.annotate_rendered_view_with_filenames = true

    # Strict loading - just log, don't error out the page!
    config.active_record.action_on_strict_loading_violation = :log

    # Just starting to use Rails caching on 7.1, so we're current
    config.active_support.cache_format_version = 7.1

    # Set up memcached as the cache store everywhere
    config.cache_store = :mem_cache_store
  end
end

MO = MushroomObserver::Application.config
require_relative("consts")
