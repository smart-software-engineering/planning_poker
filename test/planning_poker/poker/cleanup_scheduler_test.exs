defmodule PlanningPoker.Poker.CleanupSchedulerTest do
  use PlanningPoker.DataCase

  alias PlanningPoker.Poker
  alias PlanningPoker.Poker.CleanupScheduler
  alias PlanningPoker.Repo

  import Ecto.Query
  import PlanningPoker.PokerFixtures

  describe "CleanupScheduler" do
    test "deletes closed poker sessions older than 10 minutes" do
      # Create a poker session and close it
      poker = poker_fixture()
      {:ok, closed_poker} = Poker.close_poker(poker)

      # Manually set updated_at to be older than 10 minutes
      eleven_minutes_ago = DateTime.utc_now() |> DateTime.add(-11 * 60, :second)

      from(p in PlanningPoker.Poker.Poker, where: p.id == ^closed_poker.id)
      |> Repo.update_all(set: [updated_at: eleven_minutes_ago])

      # Verify poker exists before cleanup
      assert Poker.get_poker(closed_poker.id) != nil

      # Start the cleanup scheduler and trigger cleanup immediately
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)

      # Give it time to process
      :timer.sleep(100)

      # Verify poker is deleted
      assert Poker.get_poker(closed_poker.id) == nil

      GenServer.stop(pid)
    end

    test "does not delete open poker sessions" do
      poker = poker_fixture()

      # Set updated_at to be older than 10 minutes (but session is not closed)
      eleven_minutes_ago = DateTime.utc_now() |> DateTime.add(-11 * 60, :second)

      from(p in PlanningPoker.Poker.Poker, where: p.id == ^poker.id)
      |> Repo.update_all(set: [updated_at: eleven_minutes_ago])

      # Start the cleanup scheduler and trigger cleanup immediately
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)

      # Give it time to process
      :timer.sleep(100)

      # Verify poker still exists (not deleted because it's not closed)
      assert Poker.get_poker(poker.id) != nil

      GenServer.stop(pid)
    end

    test "does not delete recently closed poker sessions" do
      poker = poker_fixture()
      {:ok, closed_poker} = Poker.close_poker(poker)

      # Session is closed but recently updated (within 10 minutes)
      # So it should not be deleted

      # Start the cleanup scheduler and trigger cleanup immediately
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)

      # Give it time to process
      :timer.sleep(100)

      # Verify poker still exists (not deleted because it's too recent)
      assert Poker.get_poker(closed_poker.id) != nil

      GenServer.stop(pid)
    end

    test "handles multiple poker sessions correctly" do
      # Create multiple poker sessions with different states
      poker1 = poker_fixture(name: "Poker 1")
      poker2 = poker_fixture(name: "Poker 2")
      poker3 = poker_fixture(name: "Poker 3")

      # Close poker1 and poker2, leave poker3 open
      {:ok, closed_poker1} = Poker.close_poker(poker1)
      {:ok, closed_poker2} = Poker.close_poker(poker2)

      eleven_minutes_ago = DateTime.utc_now() |> DateTime.add(-11 * 60, :second)
      five_minutes_ago = DateTime.utc_now() |> DateTime.add(-5 * 60, :second)

      # Set poker1 to be old enough for deletion
      from(p in PlanningPoker.Poker.Poker, where: p.id == ^closed_poker1.id)
      |> Repo.update_all(set: [updated_at: eleven_minutes_ago])

      # Set poker2 to be too recent for deletion
      from(p in PlanningPoker.Poker.Poker, where: p.id == ^closed_poker2.id)
      |> Repo.update_all(set: [updated_at: five_minutes_ago])

      # Set poker3 to be old but open (should not be deleted)
      from(p in PlanningPoker.Poker.Poker, where: p.id == ^poker3.id)
      |> Repo.update_all(set: [updated_at: eleven_minutes_ago])

      # Start cleanup
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)
      :timer.sleep(100)

      # Only poker1 should be deleted
      assert Poker.get_poker(closed_poker1.id) == nil
      assert Poker.get_poker(closed_poker2.id) != nil
      assert Poker.get_poker(poker3.id) != nil

      GenServer.stop(pid)
    end

    test "auto-terminates poker sessions inactive for 48+ hours" do
      # Create a poker session
      poker = poker_fixture()

      # Set updated_at to be older than 48 hours (but session is still open)
      forty_nine_hours_ago = DateTime.utc_now() |> DateTime.add(-49 * 60 * 60, :second)

      from(p in PlanningPoker.Poker.Poker, where: p.id == ^poker.id)
      |> Repo.update_all(set: [updated_at: forty_nine_hours_ago])

      # Verify poker is open before cleanup
      updated_poker = Poker.get_poker(poker.id)
      assert updated_poker.closed_at == nil

      # Start the cleanup scheduler and trigger cleanup immediately
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)

      # Give it time to process
      :timer.sleep(200)

      # Verify poker is auto-terminated
      updated_poker = Poker.get_poker(poker.id)
      # Still exists
      assert updated_poker != nil
      # But now closed
      assert updated_poker.closed_at != nil

      GenServer.stop(pid)
    end

    test "does not auto-terminate poker sessions inactive for less than 48 hours" do
      # Create a poker session
      poker = poker_fixture()

      # Set updated_at to be 47 hours ago (less than 48 hours)
      forty_seven_hours_ago = DateTime.utc_now() |> DateTime.add(-47 * 60 * 60, :second)

      from(p in PlanningPoker.Poker.Poker, where: p.id == ^poker.id)
      |> Repo.update_all(set: [updated_at: forty_seven_hours_ago])

      # Verify poker is open before cleanup
      updated_poker = Poker.get_poker(poker.id)
      assert updated_poker.closed_at == nil

      # Start the cleanup scheduler and trigger cleanup immediately
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)

      # Give it time to process
      :timer.sleep(200)

      # Verify poker is still open (not auto-terminated)
      updated_poker = Poker.get_poker(poker.id)
      # Still exists
      assert updated_poker != nil
      # Still open
      assert updated_poker.closed_at == nil

      GenServer.stop(pid)
    end

    test "auto-terminated sessions are scheduled for deletion after grace period" do
      # Create a poker session
      poker = poker_fixture()

      # Set updated_at to be older than 48 hours
      forty_nine_hours_ago = DateTime.utc_now() |> DateTime.add(-49 * 60 * 60, :second)

      from(p in PlanningPoker.Poker.Poker, where: p.id == ^poker.id)
      |> Repo.update_all(set: [updated_at: forty_nine_hours_ago])

      # Start the cleanup scheduler and trigger cleanup immediately
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)

      # Give it time to process
      :timer.sleep(200)

      # Verify poker is auto-terminated but not yet deleted
      updated_poker = Poker.get_poker(poker.id)
      # Still exists
      assert updated_poker != nil
      # Now closed
      assert updated_poker.closed_at != nil

      # Manually set the updated_at to be older than 10 minutes to simulate the grace period passing
      twelve_minutes_ago = DateTime.utc_now() |> DateTime.add(-12 * 60, :second)

      from(p in PlanningPoker.Poker.Poker, where: p.id == ^updated_poker.id)
      |> Repo.update_all(set: [updated_at: twelve_minutes_ago])

      # Run cleanup again - this time it should delete the auto-terminated session
      send(pid, :cleanup)
      :timer.sleep(200)

      # Now it should be deleted
      assert Poker.get_poker(poker.id) == nil

      GenServer.stop(pid)
    end

    test "comprehensive cleanup test - multiple scenarios" do
      # Create multiple poker sessions with different states
      # Open, recently active
      poker1 = poker_fixture(name: "Open Recent")
      # Open, 49+ hours old
      poker2 = poker_fixture(name: "Open Old")
      # Closed, recently closed
      poker3 = poker_fixture(name: "Closed Recent")
      # Closed, 11+ minutes ago
      poker4 = poker_fixture(name: "Closed Old")

      # Set up different timestamps
      now = DateTime.utc_now()
      five_minutes_ago = DateTime.add(now, -5 * 60, :second)
      eleven_minutes_ago = DateTime.add(now, -11 * 60, :second)
      forty_nine_hours_ago = DateTime.add(now, -49 * 60 * 60, :second)

      # Close poker3 and poker4
      {:ok, closed_poker3} = Poker.close_poker(poker3)
      {:ok, closed_poker4} = Poker.close_poker(poker4)

      # Set timestamps
      # poker1: recent, open - should stay
      from(p in PlanningPoker.Poker.Poker, where: p.id == ^poker1.id)
      |> Repo.update_all(set: [updated_at: five_minutes_ago])

      # poker2: old, open - should be auto-terminated
      from(p in PlanningPoker.Poker.Poker, where: p.id == ^poker2.id)
      |> Repo.update_all(set: [updated_at: forty_nine_hours_ago])

      # poker3: closed recently - should stay
      from(p in PlanningPoker.Poker.Poker, where: p.id == ^closed_poker3.id)
      |> Repo.update_all(set: [updated_at: five_minutes_ago])

      # poker4: closed old - should be deleted
      from(p in PlanningPoker.Poker.Poker, where: p.id == ^closed_poker4.id)
      |> Repo.update_all(set: [updated_at: eleven_minutes_ago])

      # Run cleanup
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      send(pid, :cleanup)
      :timer.sleep(200)

      # Check results
      result1 = Poker.get_poker(poker1.id)
      result2 = Poker.get_poker(poker2.id)
      result3 = Poker.get_poker(closed_poker3.id)
      result4 = Poker.get_poker(closed_poker4.id)

      # poker1: should still exist and be open
      assert result1 != nil
      assert result1.closed_at == nil

      # poker2: should still exist but now be closed (auto-terminated)
      assert result2 != nil
      assert result2.closed_at != nil

      # poker3: should still exist and be closed
      assert result3 != nil
      assert result3.closed_at != nil

      # poker4: should be deleted
      assert result4 == nil

      GenServer.stop(pid)
    end

    test "cleanup scheduler can be started and stopped" do
      # Just test that the scheduler can be started and stopped without error
      {:ok, pid} = GenServer.start_link(CleanupScheduler, %{})
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end
end
