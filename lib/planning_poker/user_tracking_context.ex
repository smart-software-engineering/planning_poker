defmodule PlanningPoker.UserTrackingContext do
  @moduledoc """
  Context module for user tracking that properly delegates to the supervisor and server.
  """

  @behaviour PlanningPoker.UserTrackingBehaviour

  alias PlanningPoker.UserTracking.{UserTrackingServer, UserTrackingSupervisor}

  @impl PlanningPoker.UserTrackingBehaviour
  def stop_user_tracking(poker_id) do
    UserTrackingSupervisor.stop_user_tracking(poker_id)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def start_user_tracking(poker_id) do
    UserTrackingSupervisor.start_user_tracking(poker_id)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def join_user(poker_id, username) do
    UserTrackingServer.join_user(poker_id, username)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def mark_user_online(poker_id, username, pid) do
    UserTrackingServer.mark_user_online(poker_id, username, pid)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def mark_user_offline(poker_id, username, pid) do
    UserTrackingServer.mark_user_offline(poker_id, username, pid)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def toggle_mute_user(poker_id, username) do
    UserTrackingServer.toggle_mute_user(poker_id, username)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def get_users(poker_id) do
    UserTrackingServer.get_users(poker_id)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def get_online_users(poker_id) do
    UserTrackingServer.get_online_users(poker_id)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def get_unmuted_online_users(poker_id) do
    UserTrackingServer.get_unmuted_online_users(poker_id)
  end

  @impl PlanningPoker.UserTrackingBehaviour
  def username_available?(poker_id, username) do
    UserTrackingServer.username_available?(poker_id, username)
  end
end
