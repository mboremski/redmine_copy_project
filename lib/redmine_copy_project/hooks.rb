# frozen_string_literal: true

module RedmineCopyProject
  # Adds the "Copy" link to the actions dropdown of the project overview.
  #
  # The hook :view_project_actions_dropdown is provided by the additionals
  # plugin, whose projects/show template replaces the core one. The core
  # template has no hook inside its dropdown.
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_project_actions_dropdown, partial: 'hooks/redmine_copy_project/actions_dropdown'
  end
end
