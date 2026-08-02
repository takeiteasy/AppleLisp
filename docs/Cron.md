# Cron API

Schedule recurring tasks using cron expressions.

## API Reference

| Method | Description |
|--------|-------------|
| `(.schedule expression callback)` | Schedule a job with a standard 5-field cron expression. Returns a job ID string. |
| `(.unschedule id)` | Cancel a scheduled job by its ID. |
| `(.list)` | List all scheduled jobs with their IDs, expressions, and last run times. |

## Examples

```clojure
(def Cron (require "macos/Cron"))

;; Schedule a job every 5 minutes
(def jobId (.schedule Cron "*/5 * * * *" (fn []
  (print "Cron job executed: 5 minute mark"))))

;; List scheduled jobs
(print (.list Cron))

;; Unschedule the job
(.unschedule Cron jobId)
```

The scheduler ticks at the start of every minute. Standard cron syntax is supported: `*`, ranges (`1-5`), steps (`*/5`), comma-separated lists (`1,3,5`), and combinations.
