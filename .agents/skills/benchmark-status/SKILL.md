# /benchmark-status

Check all running benchmark campaigns, report status of each dataset, and identify any that have failed or stalled.

## Steps

1. Look for benchmark run directories and PID files under the project tree
2. Check which benchmark processes are still running (`ps aux | grep` or PID file checks)
3. Scan for checkpoint/resume files (e.g. `_progress.json`, `checkpoint*.json`)
4. For each campaign/dataset, report:
   - Name and target
   - Status: running / completed / failed / stalled
   - Progress (entries processed / total)
   - Last log timestamp
   - Any error messages in logs
5. Summarize: total campaigns, how many OK, how many need attention
6. If any are stalled, suggest recovery commands (resume from checkpoint)

## Constraints

- Read-only: do not start, stop, or modify any benchmark runs
- Check FlexAIDdS benchmarks in `/Users/lp.more/Documents/PhD/Programs/FlexAIDdS` as well
- Report concisely — one line per campaign, then a summary
