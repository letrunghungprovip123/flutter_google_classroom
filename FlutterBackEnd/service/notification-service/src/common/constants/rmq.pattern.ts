export const RMQ_PATTERN_NOTIFICATIONS = {
  CREATE: 'create_notification',
  GET_BY_USER: 'get_notifications_by_user',
  MARK_AS_READ: 'mark_as_read_notification',
};

export const RMQ_PATTERN_ANNOUNCEMENTS = {
  CREATE: 'create_announcement',
  GET_BY_COURSE: 'get_announcements_by_course',
  DETAIL: 'get_announcement_detail',
  UPDATE: 'update_announcement',
  DELETE: 'delete_announcement',
};

export const RMQ_PATTERN_COMMENTS = {
  CREATE: 'create',
  GET_BY_ANNOUNCEMENT: 'get_by_announcement',
  DELETE: 'delete',
};