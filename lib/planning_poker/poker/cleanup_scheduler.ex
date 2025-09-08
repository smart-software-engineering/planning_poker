defmodule PlanningPoker.Poker.CleanupScheduler do
  @moduledoc """
  A GenServer that runs cleanup tasks periodically.

  This scheduler performs two main cleanup operations:

  1. **Auto-termination**: Poker sessions that are open but inactive for 48+ hours
     are automatically closed. Their updated_at is set to allow deletion after
     a 10-minute grace period.
     
  2. **Deletion**: Poker sessions that have been closed for more than 10 minutes
     are permanently deleted from the database.

  The scheduler runs every 10 minutes and uses simple SQL statements that are
  safe to run on multiple instances without complex locking mechanisms.

  ## Cleanup Rules
  - Open sessions: Auto-terminated after 48 hours of inactivity
  - Closed sessions: Deleted after 10 minutes 
  - Auto-terminated sessions: Given 5-minute grace period before deletion eligibility
  """
  use GenServer

  alias PlanningPoker.Repo
  import Ecto.Query

  require Logger

  # Run cleanup every 10 minutes (600,000 milliseconds)
  @cleanup_interval 10 * 60 * 1000
  # Delete sessions closed more than 10 minutes ago
  @cleanup_threshold 10 * 60
  # Auto-terminate sessions inactive for more than 48 hours
  @auto_terminate_threshold 48 * 60 * 60

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Schedule the first cleanup with some jitter to avoid all instances starting at once
    # 0-60 seconds
    jitter = :rand.uniform(60_000)
    Process.send_after(self(), :cleanup, jitter)
    Logger.info("PlanningPoker CleanupScheduler started with #{jitter}ms jitter")
    {:ok, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    perform_auto_termination()
    perform_cleanup()
    # Schedule the next cleanup
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp perform_auto_termination do
    auto_terminate_time = DateTime.utc_now() |> DateTime.add(-@auto_terminate_threshold, :second)
    # Set updated_at to 5 minutes ago so it won't be immediately deleted
    future_deletion_time = DateTime.utc_now() |> DateTime.add(-5 * 60, :second)

    # Find poker sessions that are open but inactive for 48+ hours
    query =
      from p in "poker",
        where: is_nil(p.closed_at) and p.updated_at < ^auto_terminate_time

    case Repo.update_all(query,
           set: [closed_at: DateTime.utc_now(), updated_at: future_deletion_time]
         ) do
      {count, _} when count > 0 ->
        Logger.info(
          "CleanupScheduler: Auto-terminated #{count} inactive poker sessions (48+ hours)"
        )

      {0, _} ->
        Logger.debug("CleanupScheduler: No poker sessions to auto-terminate")

      error ->
        Logger.error("CleanupScheduler: Error during auto-termination: #{inspect(error)}")
    end
  end

  defp perform_cleanup do
    cutoff_time = DateTime.utc_now() |> DateTime.add(-@cleanup_threshold, :second)

    # Use a simple DELETE statement that's safe to run on multiple instances
    # PostgreSQL will handle concurrent deletes gracefully
    query =
      from p in "poker",
        where: not is_nil(p.closed_at) and p.updated_at < ^cutoff_time

    case Repo.delete_all(query) do
      {count, _} when count > 0 ->
        Logger.info("CleanupScheduler: Successfully deleted #{count} closed poker sessions")

      {0, _} ->
        Logger.debug("CleanupScheduler: No poker sessions to clean up")

      error ->
        Logger.error("CleanupScheduler: Error during cleanup: #{inspect(error)}")
    end
  end
end
