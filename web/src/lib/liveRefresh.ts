// Coalesces bursts of realtime events into a single refetch and skips work
// while the tab is hidden (it catches up as soon as the tab is visible again).
// With many users online, every DB change fans out to every open client, so
// this keeps one change from turning into N immediate full-table refetches.
export function createLiveRefresh(run: () => Promise<void> | void, delay = 800) {
  let timer: ReturnType<typeof setTimeout> | null = null
  let stale = false
  let running = false

  async function execute() {
    if (running) { stale = true; return }
    running = true
    try { await run() } finally {
      running = false
      if (stale && !document.hidden) { stale = false; void execute() }
    }
  }

  function fire() {
    timer = null
    if (document.hidden) { stale = true; return }
    void execute()
  }

  function request() {
    if (timer) clearTimeout(timer)
    timer = setTimeout(fire, delay)
  }

  function onVisibility() {
    if (!document.hidden && stale) { stale = false; void execute() }
  }

  document.addEventListener('visibilitychange', onVisibility)
  function dispose() {
    if (timer) clearTimeout(timer)
    document.removeEventListener('visibilitychange', onVisibility)
  }
  return { request, dispose }
}
