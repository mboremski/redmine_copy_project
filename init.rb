# frozen_string_literal: true

# Redmine Copy Project plugin
#
# Adds a project-level permission "Copy project" so that members can copy a
# project without being administrator. See README.md.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.

Redmine::Plugin.register :redmine_copy_project do
  name 'Redmine Copy Project'
  author 'Markus Boremski'
  description 'Adds a "Copy project" permission so that project members can copy a project without being administrator (redmine.org #4687)'
  version '1.0.0'
  url 'https://github.com/mboremski/redmine_copy_project'
  author_url 'https://github.com/mboremski'

  requires_redmine version_or_higher: '6.1'

  # Project-level permission outside any module, so it is always available.
  # :require => :member keeps it off the Anonymous and Non member roles.
  permission :copy_project, {projects: [:copy]}, require: :member
end

# init.rb already runs inside Rails' to_prepare (Redmine::PluginLoader.load),
# so the patch is applied unwrapped. lib/ is a Zeitwerk eager-load path;
# referencing the constants is enough to load them.
ProjectsController.prepend RedmineCopyProject::ProjectsControllerPatch
RedmineCopyProject::Hooks
