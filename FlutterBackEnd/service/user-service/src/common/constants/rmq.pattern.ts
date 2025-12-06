// src/common/constants/rmq.pattern.ts
export const RMQ_PATTERN_SEMESTERS = {
  LIST: 'semesters_list',
  GET: 'semesters_get',
  CREATE: 'semesters_create',
  UPDATE: 'semesters_update',
  DELETE: 'semesters_delete',
};

export const RMQ_PATTERN_COURSES = {
  LIST: 'courses_list', // filter: { semesterId? }
  GET: 'courses_get',
  CREATE: 'courses_create',
  UPDATE: 'courses_update',
  DELETE: 'courses_delete',
  GET_STUDENT_COURSE: 'get_student_course',
  GET_ALL_STUDENT: 'get_all_student',
};

export const RMQ_PATTERN_GROUPS = {
  LIST: 'groups_list', // filter: { courseId }
  CREATE: 'groups_create',
  UPDATE: 'groups_update',
  DELETE: 'groups_delete',
  IMPORT_CSV: 'groups_import_csv', // { rows, preview? }
};

export const RMQ_PATTERN_STUDENTS = {
  LIST: 'students_list', // GET /students?groupId=
  DETAIL: 'students_detail', // GET /students/:id
  CREATE: 'students_create', // POST /students
  UPDATE: 'students_update', // PUT /students/:id
  DELETE: 'students_delete', // DELETE /students/:id
  IMPORT_CSV: 'students_import_csv', // POST /students/import
};

export const RMQ_PATTERN_AUTH = {
  SIGNUP: 'signup_user',
  LOGIN: 'login_user',
  PROFILE: 'get_profile',
  UPDATE_PROFILE: 'update_profile',
  GET_DASHBOARD: 'get_dashboard',
};

export const RMQ_PATTERN_MATERIALS = {
  CREATE: 'create_material',
  GET_BY_COURSE: 'get_materials_by_course',
  GET_BY_ID: 'get_material_by_id',
  DELETE: 'delete_material',
  // optional (chưa có bảng view, có thể mock hoặc bỏ qua)
  TRACK_VIEW: 'track_material_view',
};

export const RMQ_PATTERN_STUDENT = {
  IMPORT_PREVIEW: 'student.import.preview',
  IMPORT_CONFIRM: 'student.import.confirm',
  GET_ALL: 'student.get.all',
  DELETE: 'student.delete',
};

// rmq-patterns.ts
export const RMQ_PATTERN_STUDENT_GROUP = {
  IMPORT_PREVIEW: 'student-group.import.preview',
  IMPORT_CONFIRM: 'student-group.import.confirm',
  CREATE_ONE: 'student-group.create.one',
  REMOVE_ONE: 'student-group.remove.one',
};

export const RMQ_PATTERN_INSTRUCTOR_DASHBOARD = {
  GET_OVERVIEW: 'intructor_dashboard_get_overview',
  GET_PROGRESS: 'instructor_dashboard_get_progress',
  EXPORT_CSV: 'instructor_dashboard_export_csv',
};


export const RMQ_PATTERN_CHAT = {
  GET_CONVERSATION: 'chat.getConversation', // lấy 1 cuộc trò chuyện với instructor
  LIST_CONVERSATIONS: 'chat.listConversations', // instructor xem list
  CREATE_CONVERSATION: 'chat.createConversation', // tạo nếu chưa có
  GET_MESSAGES: 'chat.getMessages', // lấy lịch sử tin nhắn
  SEND_MESSAGE: 'chat.sendMessage', // gửi tin nhắn
  MARK_READ: 'chat.markRead', // đánh dấu đã đọc
} as const;
