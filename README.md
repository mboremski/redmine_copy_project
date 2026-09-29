# Redmine Copy Project

Adds a project-level permission **Copy project** so that project members can
copy a project without being administrator. This is the long-standing feature
request [redmine.org #4687](https://www.redmine.org/issues/4687) as a plugin
instead of a core patch.

## What it does

* Registers the permission `copy_project` (outside any project module, members
  only, so it cannot be given to the *Anonymous* and *Non member* roles).
* Lets users with that permission on the **source** project use the core copy
  form (`/projects/:id/copy`). Everything else the core does when copying —
  parent selection, public flag, modules, members, issues, wiki … — is unchanged.
* Adds the **Copy** link to the actions dropdown of the project overview for
  users with the permission. The link is rendered through the hook
  `view_project_actions_dropdown` of the
  [additionals](https://github.com/AlphaNodes/additionals) plugin, whose
  `projects/show` template replaces the core one; without additionals the copy
  form is still reachable via the URL, only the link is missing.
* As with a newly created project, a non-admin copier becomes a member of the
  copy with the role from *Administration → Settings → Projects → Role given to
  a non-admin user who creates a project*, unless the copied members already
  include them.

Archiving, unarchiving and bulk deletion of projects stay admin-only.

## What it does not do

`copy_project` only unlocks the copy action. Creating the copy still needs the
core permission to create a project at the chosen place: **Create project**
(top-level) or **Create subprojects** on the parent. A role with `copy_project`
but neither of those can open the form, yet the copy fails with *Subproject of
is invalid*. Grant the permissions together.

Closed projects can only be copied by administrators (the core does not grant
non-read permissions on closed projects).

## Security note (from #4687)

Copying a project copies **all** its issues, wiki pages, documents and
attachments, including ones the copier is not allowed to see in the source, and
the copier may hold a higher role in the copy than in the source. Give
`copy_project` only to roles that already have full read access to the
projects they may copy.

## Requirements

* Redmine 6.1 or later (tested on 6.1.4)
* [additionals](https://github.com/AlphaNodes/additionals) 4.x for the link in
  the actions dropdown (optional)

## Installation

    cd /path/to/redmine/plugins
    git clone https://github.com/mboremski/redmine_copy_project.git
    # no migrations
    # restart Redmine

Then enable **Copy project** for the roles that need it under
*Administration → Roles and permissions* (section *Project*).

## Tests

    bundle exec rake redmine:plugins:test NAME=redmine_copy_project RAILS_ENV=test

## Changelog

### 1.0.0

* Initial release for Redmine 6.1.

## License

GNU General Public License v2 or later, like Redmine.
