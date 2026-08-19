INSERT INTO documents (id, path, title, source_url) VALUES
  (1, 'lessons/welcome.md', 'Welcome to the student lab', 'https://hedronite.com'),
  (2, 'lessons/lab.md', 'Run a lab job', 'https://hedronite.com'),
  (3, 'lessons/lattice.md', 'Read the lattice', 'https://hedronite.com');

INSERT INTO chunks (id, document_id, ordinal, text) VALUES
  (1, 1, 0, 'HEDRONOS 0.1. Student lab. Not the mesh. Knowledge comes from published Academy lessons.'),
  (2, 2, 0, 'Lab runner: POST /jobs with {"job":"demo","lesson_id":1}. One job at a time.'),
  (3, 3, 0, 'Disk is vault/ plus lattice.db. Schema plus demo rows only.');

INSERT INTO index_state (id, schema_version, last_indexed_at) VALUES
  (1, 1, datetime('now'));

INSERT INTO lessons (id, url, title, body_text, fetched_at, cached) VALUES
  (1, 'demo://welcome', 'Welcome to the student lab',
      'HEDRONOS 0.1. Student lab. Not the mesh. Open Lessons, then run the demo job.',
      datetime('now'), 1),
  (2, 'demo://lab', 'Run a lab job',
      'From Lab, run job demo. The kernel returns stdout. One job at a time.',
      datetime('now'), 1),
  (3, 'demo://lattice', 'Read the lattice',
      'Lattice is schema plus demo rows. Not Evan''s Akasha.',
      datetime('now'), 1);
