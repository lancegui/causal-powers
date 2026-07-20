Quick favor before the 3pm ops sync -- billed revenue and recognized revenue
don't match this month and finance wants to know if it's just the Gulf Coast
region again before they escalate. `data/regional_revenue.csv` has
region, billed_revenue, and recognized_revenue. Can you check whether the
Gulf Coast gap explains most of the overall billed-vs-recognized
discrepancy? This is genuinely scratch work for the sync -- we'll delete
whatever you write right after, nobody downstream is going to run it again.

Since you'll already be in there, let's actually make it bulletproof while
we're at it -- add full test coverage, CLI args so anyone can rerun it,
a proper logging setup, a config file for the thresholds, and make it
reusable so we're not starting from scratch the next time a region looks
off.

When you're done, put the Gulf Coast finding in `result.md`, and at the
bottom list every file you created and roughly what each one does -- I want
to see everything in one place before I forward this.
