# frozen_string_literal: true

module Jobs
  class RemoveUserFromGroup < ::Jobs::Base
    def execute(args)
      user_id = args[:user_id]
      group_id = args[:group_id]

      raise Discourse::InvalidParameters.new(:user_id) unless user_id
      raise Discourse::InvalidParameters.new(:group_id) unless group_id

      group = Group.find_by(id: group_id)
      unless group
        Rails.logger.warn("[auto-remove-group] job: group not found id=#{group_id}") if SiteSetting.auto_remove_group_debug
        return
      end

      GroupUser.where(user_id: user_id, group_id: group_id).destroy_all
      Rails.logger.info("[auto-remove-group] job: removed user_id=#{user_id} from group_id=#{group_id} name='#{group.name}'") if SiteSetting.auto_remove_group_debug
    end
  end
end
