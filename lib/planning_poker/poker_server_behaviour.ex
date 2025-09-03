defmodule PlanningPoker.PokerServerBehaviour do
  @moduledoc """
  Behaviour for PokerServer implementations.
  Allows for dependency injection and testing without environment checks.
  """

  @doc """
  Finds or starts a PokerServer for the given poker ID.
  """
  @callback find_or_start(poker_id :: binary()) :: :ok | {:error, term()}

  @doc """
  Gets the current game state from the PokerServer.
  """
  @callback get_game_state(poker_id :: binary()) :: {:ok, map()} | {:error, term()}

  @doc """
  Adds a user to the game session.
  """
  @callback add_user(poker_id :: binary(), user_name :: binary(), user_role :: atom()) ::
              :ok | {:error, term()}

  @doc """
  Removes a user from the game session.
  """
  @callback remove_user(poker_id :: binary(), user_name :: binary()) ::
              :ok | {:error, term()}

  @doc """
  Gets all active users in the game.
  """
  @callback get_users(poker_id :: binary()) :: {:ok, map()} | {:error, term()}
end
