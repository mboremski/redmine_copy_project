# frozen_string_literal: true

module RedmineCopyProject
  # Lets members with the :copy_project permission use ProjectsController#copy,
  # which the core restricts to administrators.
  module ProjectsControllerPatch
    def self.prepended(base)
      # The core declares
      #   before_action :require_admin, :only => [:copy, :archive, :unarchive, :bulk_destroy]
      # Skipping it for :copy only leaves the other three actions admin-only.
      base.skip_before_action :require_admin, only: :copy
      base.before_action :authorize_copy_project, only: :copy
    end

    # Same as ProjectsController#create: a non-admin who creates a project
    # becomes its default member, otherwise the copy would be invisible to
    # them when "Members" is not copied.
    def copy
      super
      return unless request.post? && @project&.persisted?
      return if User.current.admin? || @project.members.exists?(user_id: User.current.id)

      @project.add_default_member(User.current)
    end

    private

    # The permission is checked against the *source* project. The copy
    # action does not use find_project, so the source is looked up here.
    def authorize_copy_project
      source = Project.find(params[:id])
      return if User.current.admin? || User.current.allowed_to?(:copy_project, source)

      deny_access
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
