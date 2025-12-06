// common/constants/rmq.pattern.ts
export const RMQ_PATTERN_ASSIGNMENTS = {
  GET: 'get_assignments',
  GET_BY_ID: 'get_assignment_by_id',
  CREATE: 'create_assignment',
  UPDATE: 'update_assignment',
  DELETE: 'delete_assignment',
  SUMMARY: 'get_assignment_summary',
  // (tuỳ chọn) EXPORT_CSV: 'export_assignments_csv',
};

export const RMQ_PATTERN_SUBMISSIONS = {
  CREATE: 'create_submission',
  GET_BY_ASSIGNMENT: 'get_submissions_by_assignment',
  GRADE: 'grade_submission',
  GET_MY: 'get_my',
};

export const RMQ_PATTERN_QUIZZES = {
  CREATE: 'create_quiz',
  GET_ALL: 'get_quizzes',
  GET_BY_ID: 'get_quiz_by_id',
  UPDATE: 'update_quiz',
  DELETE: 'delete_quiz',
};

export const RMQ_PATTERN_QUIZ_ATTEMPTS = {
  START: 'start_quiz_attempt', // POST /quiz-attempts
  SUBMIT: 'submit_quiz_attempt', // PUT /quiz-attempts/:id/submit
  GET_BY_QUIZ: 'get_quiz_attempts_by_quiz', // GET /quiz-attempts/:quizId
};


export const RMQ_PATTERN_QUESTION_BANK = {
  CREATE: 'questionbank.create',
  DELETE: 'questionbank.delete',
  GET_ALL_BY_COURSE: 'questionbank.getAllByCourse',
  GET_BY_ID: 'questionbank.getById',
};
