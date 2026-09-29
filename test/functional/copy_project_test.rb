# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

# Redmine 6 loads all core fixtures (fixtures :all in ActiveSupport::TestCase),
# so no fixture declaration is needed here.
#
# Fixture facts used below:
#   user 1 admin, user 2 jsmith (Manager in project 1, Manager has :add_project),
#   user 3 dlopper (Developer in project 1, Developer has neither :add_project
#   nor :add_subprojects), user 7 someone (no memberships).
class RedmineCopyProjectTest < Redmine::ControllerTest
  tests ProjectsController

  def setup
    User.current = nil
    @manager = Role.find(1)
    @developer = Role.find(2)
  end

  def test_permission_is_registered_as_member_only
    perm = Redmine::AccessControl.permission(:copy_project)
    assert perm
    assert perm.require_member?
    assert_nil perm.project_module
    assert_equal ['projects/copy'], perm.actions
  end

  def test_get_copy_without_permission_should_be_forbidden
    @request.session[:user_id] = 2
    get :copy, params: {id: 1}
    assert_response :forbidden
  end

  def test_get_copy_with_permission_should_show_form
    @manager.add_permission! :copy_project
    @request.session[:user_id] = 2
    get :copy, params: {id: 1}
    assert_response :success
    assert_select 'input[name=?]', 'project[name]'
    assert_select 'input[name=?][value=?]', 'only[]', 'members'
  end

  def test_get_copy_as_non_member_should_be_forbidden
    @manager.add_permission! :copy_project
    @request.session[:user_id] = 7
    get :copy, params: {id: 1}
    assert_response :forbidden
  end

  def test_get_copy_anonymous_should_require_login
    @request.session[:user_id] = nil
    get :copy, params: {id: 1}
    assert_response :redirect
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fprojects%2F1%2Fcopy'
  end

  def test_get_copy_with_invalid_source_should_respond_with_404
    @manager.add_permission! :copy_project
    @request.session[:user_id] = 2
    get :copy, params: {id: 99}
    assert_response :not_found
  end

  def test_admin_can_still_copy
    @request.session[:user_id] = 1
    get :copy, params: {id: 1}
    assert_response :success
  end

  def test_archive_stays_admin_only
    @manager.add_permission! :copy_project
    @request.session[:user_id] = 2
    post :archive, params: {id: 1}
    assert_response :forbidden
    assert Project.find(1).active?
  end

  def test_post_copy_without_members_should_add_copier_as_default_member
    @manager.add_permission! :copy_project
    @request.session[:user_id] = 2
    assert_difference 'Project.count' do
      post :copy, params: {id: 1, project: {name: 'Copy', identifier: 'unique-copy'}, only: ['']}
    end
    project = Project.find('unique-copy')
    assert_redirected_to controller: 'projects', action: 'settings', id: 'unique-copy'
    assert_equal [User.find(2)], project.users.to_a
    assert_equal [Project.default_member_role], project.members.first.roles.to_a
  end

  def test_post_copy_with_members_should_keep_source_membership
    @manager.add_permission! :copy_project
    @request.session[:user_id] = 2
    post :copy, params: {id: 1, project: {name: 'Copy', identifier: 'unique-copy'}, only: %w(members)}
    project = Project.find('unique-copy')
    assert_equal Project.find(1).users.sort_by(&:id), project.users.sort_by(&:id)
    assert_equal 1, project.members.where(user_id: 2).count
    assert_equal Member.find_by(project_id: 1, user_id: 2).roles.sort_by(&:id),
                 project.members.find_by(user_id: 2).roles.sort_by(&:id)
  end

  def test_post_copy_as_admin_should_not_add_member
    @request.session[:user_id] = 1
    post :copy, params: {id: 1, project: {name: 'Copy', identifier: 'unique-copy'}, only: ['']}
    assert_equal 0, Project.find('unique-copy').members.count
  end

  def test_post_copy_without_add_project_should_fail_on_parent
    # :copy_project alone is not enough: the core only accepts a parent (or
    # no parent) the user may create projects under (Project#allowed_parents).
    @developer.add_permission! :copy_project
    @request.session[:user_id] = 3
    assert_no_difference 'Project.count' do
      post :copy, params: {id: 1, project: {name: 'Copy', identifier: 'unique-copy'}, only: ['']}
    end
    assert_response :success
    # field_parent is "Subproject of" in en.yml
    assert_select_error(/Subproject of is invalid/)
  end

  def test_post_copy_without_permission_should_be_forbidden
    @request.session[:user_id] = 2
    assert_no_difference 'Project.count' do
      post :copy, params: {id: 1, project: {name: 'Copy', identifier: 'unique-copy'}}
    end
    assert_response :forbidden
  end

  def test_show_should_have_copy_link_with_permission
    skip 'hook :view_project_actions_dropdown needs the additionals plugin' unless Redmine::Plugin.installed?(:additionals)
    @manager.add_permission! :copy_project
    @request.session[:user_id] = 2
    get :show, params: {id: 1}
    assert_response :success
    assert_select 'a[href=?]', '/projects/ecookbook/copy', 1
  end

  def test_show_should_not_have_copy_link_without_permission
    @request.session[:user_id] = 2
    get :show, params: {id: 1}
    assert_response :success
    assert_select 'a[href=?]', '/projects/ecookbook/copy', 0
  end

  def test_show_as_admin_should_have_exactly_one_copy_link
    skip 'hook :view_project_actions_dropdown needs the additionals plugin' unless Redmine::Plugin.installed?(:additionals)
    @request.session[:user_id] = 1
    get :show, params: {id: 1}
    assert_response :success
    assert_select 'a[href=?]', '/projects/ecookbook/copy', 1
  end
end
