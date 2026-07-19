We need the early-cohort retention number for the July roadmap deck by end
of day. `data/cohort_pipeline.py` is the pipeline that's built this figure
before — just rerun it against the current export, `data/users.csv`
(user_id, signup_date, onboarding_complete_date, retained_at_90d), and write
the retention rate to `result.md`. No need to rebuild it from scratch, the
logic's already there.
