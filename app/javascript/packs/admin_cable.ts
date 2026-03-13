import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

document.addEventListener("DOMContentLoaded", () => {
  const statusEl = document.getElementById("analysis-status")
  if (!statusEl) return

  const weekId = statusEl.dataset.weekId
  const timerEl = document.getElementById("analysis-timer")
  const messageEl = document.getElementById("analysis-message")
  const loaderEl = document.getElementById("analysis-loader")
  let startTime: number | null = null
  let timerInterval: ReturnType<typeof setInterval> | null = null

  function formatElapsed(ms: number): string {
    const secs = Math.floor(ms / 1000)
    return `${secs}s`
  }

  function startTimer() {
    startTime = Date.now()
    if (loaderEl) loaderEl.style.display = "inline-block"
    timerInterval = setInterval(() => {
      if (timerEl && startTime) {
        timerEl.textContent = formatElapsed(Date.now() - startTime)
      }
    }, 1000)
  }

  function stopTimer() {
    if (timerInterval) clearInterval(timerInterval)
    if (loaderEl) loaderEl.style.display = "none"
  }

  // Start timer if the flash notice indicates analysis was just queued
  const flashNotice = document.querySelector(".flash.flash_notice")
  if (flashNotice?.textContent?.includes("Analysis queued")) {
    startTimer()
    if (messageEl) messageEl.textContent = "Waiting for job to start…"
  }

  consumer.subscriptions.create(
    { channel: "AnalysisChannel", week_id: weekId },
    {
      received(data: {
        status: string
        message?: string
        first_line?: string
        cost?: string
        input_tokens?: number
        output_tokens?: number
      }) {
        if (data.status === "progress") {
          if (!startTime) startTimer()
          if (messageEl) messageEl.textContent = data.message || ""
        } else if (data.status === "complete") {
          stopTimer()
          if (messageEl) {
            const elapsed = startTime ? formatElapsed(Date.now() - startTime) : ""
            const meta = [data.first_line || "Analysis complete"]
            if (data.cost) meta.push(data.cost)
            if (elapsed) meta.push(elapsed)
            messageEl.textContent = `Done — ${meta.join(" · ")}`
            messageEl.style.color = "green"
          }
          setTimeout(() => window.location.reload(), 2000)
        }
      },
    }
  )
})
