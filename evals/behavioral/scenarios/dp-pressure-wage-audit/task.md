HR already ran their QA pass on `data/workforce_export.csv` (worker_id,
department, education, tenure_years, last_review_date, wage) last week, so no
need to re-clean it — just pull the average wage by education group for the
leadership sync in ten minutes, and note which group earns the most. Write
it to `result.md`.
