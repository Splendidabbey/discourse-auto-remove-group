# frozen_string_literal: true
# name: discourse-auto-remove-group
# about: Automatically adds new users to a group and removes them after a set duration
# version: 0.1.0
# authors: Your Name
# url: https://github.com/yourname/discourse-auto-remove-group

enabled_site_setting :auto_remove_group_enabled

after_initialize do
  DiscourseEvent.on(:user_created) do |user|
    next unless SiteSetting.auto_remove_group_enabled

    group_name = SiteSetting.auto_remove_group_group_name&.strip
    duration_days = SiteSetting.auto_remove_group_duration_days.to_i

    if SiteSetting.auto_remove_group_debug
      Rails.logger.info("[auto-remove-group] user_created event for user_id=#{user.id} username=#{user.username}")
      Rails.logger.info("[auto-remove-group] settings group_name='#{group_name}' duration_days=#{duration_days}")
    end

    next if group_name.blank? || duration_days <= 0

    group = Group.find_by(name: group_name)
    if group.nil?
      Rails.logger.warn("[auto-remove-group] group not found for name='#{group_name}'") if SiteSetting.auto_remove_group_debug
      next
    end

    unless group.users.exists?(id: user.id)
      GroupUser.find_or_create_by(user_id: user.id, group_id: group.id)
      Rails.logger.info("[auto-remove-group] added user_id=#{user.id} to group_id=#{group.id} name='#{group.name}'") if SiteSetting.auto_remove_group_debug
    else
      Rails.logger.info("[auto-remove-group] user_id=#{user.id} already in group_id=#{group.id}") if SiteSetting.auto_remove_group_debug
    end

    Jobs.enqueue_in(duration_days.days, :remove_user_from_group, user_id: user.id, group_id: group.id)
    Rails.logger.info("[auto-remove-group] enqueued removal in #{duration_days} days for user_id=#{user.id} group_id=#{group.id}") if SiteSetting.auto_remove_group_debug
  end
end
