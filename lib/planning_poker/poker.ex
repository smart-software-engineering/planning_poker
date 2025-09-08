defmodule PlanningPoker.Poker do
  @moduledoc """
  The Poker context.
  """
  import Ecto.Query, warn: false
  alias PlanningPoker.Repo

  alias PlanningPoker.Poker.Poker
  alias PlanningPoker.Poker.PokerUser
  alias PlanningPoker.Poker.Voting

  @doc """
  Gets a single poker with all associations loaded.

    ## Examples

      iex> get_poker("uuid")
      %Poker{votings: [...]}  # with votings preloaded

      iex> get_poker("unknown")
      nil

  """
  def get_poker(uuid) do
    case Repo.get(Poker, uuid) do
      nil -> nil
      poker -> Repo.preload(poker, [:votings, :poker_users])
    end
  end

  @doc """
  Creates a new poker.

  ## Examples

      iex> create_poker(%{field: value})
      {:ok, %Poker{}}

      iex> create_poker(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_poker(attrs) do
    %Poker{}
    |> Poker.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a poker.

  ## Examples

      iex> update_poker(poker, %{field: new_value})
      {:ok, %Poker{}}

      iex> update_poker(poker, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_poker(%Poker{} = poker, attrs) do
    poker
    |> Poker.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Ends a poker by sending also an email about the poker to the moderator with all information including
  the voting rounds.

  ## Examples

      iex> end_poker(poker)
      {:ok, %Poker{}}

      iex> end_poker(poker)
      {:error, %Ecto.Changeset{}}

  """
  def end_poker(%Poker{} = poker) do
    # TODO send email with all information to moderator email
    Repo.delete(poker)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking poker changes.

  ## Examples

      iex> change_poker(poker)
      %Ecto.Changeset{data: %Poker{}}

  """
  def change_poker(%Poker{} = poker, attrs \\ %{}) do
    Poker.changeset(poker, attrs)
  end

  @doc """
  Closes a poker session by setting the closed_at timestamp.

  ## Examples

      iex> close_poker(poker)
      {:ok, %Poker{}}

  """
  def close_poker(%Poker{} = poker) do
    poker
    |> Poker.close_changeset(%{closed_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Reopens a poker session by clearing the closed_at timestamp.

  ## Examples

      iex> reopen_poker(poker)
      {:ok, %Poker{}}

  """
  def reopen_poker(%Poker{} = poker) do
    poker
    |> Poker.close_changeset(%{closed_at: nil})
    |> Repo.update()
  end

  @doc """
  Checks if a poker session is closed.

  ## Examples

      iex> closed?(poker)
      false

  """
  def closed?(%Poker{closed_at: nil}), do: false
  def closed?(%Poker{closed_at: _}), do: true

  ## User Management

  @doc """
  Adds a user to a poker session.

  Rejects if the username already exists in this poker session.

  ## Examples

      iex> join_poker_user(poker, "alice")
      {:ok, %PokerUser{}}

      iex> join_poker_user(poker, "existing_user")
      {:error, %Ecto.Changeset{}}

  """
  def join_poker_user(%Poker{} = poker, username) do
    %PokerUser{}
    |> PokerUser.changeset(%{
      username: username,
      joined_at: DateTime.utc_now(),
      poker_id: poker.id
    })
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        broadcast_user_update(poker.id, {:user_joined, username})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Marks a user as offline by setting left_at timestamp.

  ## Examples

      iex> leave_poker_user(poker.id, "alice")
      {:ok, %PokerUser{}}

  """
  def leave_poker_user(poker_id, username) do
    case get_poker_user_by_username(poker_id, username) do
      nil ->
        {:error, :user_not_found}

      user ->
        user
        |> PokerUser.changeset(%{left_at: DateTime.utc_now()})
        |> Repo.update()
        |> case do
          {:ok, updated_user} ->
            broadcast_user_update(poker_id, {:user_left, username})
            {:ok, updated_user}

          error ->
            error
        end
    end
  end

  @doc """
  Toggles the mute status of a user.

  ## Examples

      iex> toggle_mute_poker_user(poker.id, "alice")
      {:ok, %PokerUser{}}

  """
  def toggle_mute_poker_user(poker_id, username) do
    case get_poker_user_by_username(poker_id, username) do
      nil ->
        {:error, :user_not_found}

      user ->
        user
        |> PokerUser.changeset(%{muted: !user.muted})
        |> Repo.update()
        |> case do
          {:ok, updated_user} ->
            broadcast_user_update(poker_id, {:user_mute_changed, username, updated_user.muted})
            {:ok, updated_user}

          error ->
            error
        end
    end
  end

  @doc """
  Gets all users for a poker session.

  ## Examples

      iex> get_poker_users(poker.id)
      [%PokerUser{}, ...]

  """
  def get_poker_users(poker_id) do
    from(u in PokerUser, where: u.poker_id == ^poker_id, order_by: [asc: u.joined_at])
    |> Repo.all()
  end

  @doc """
  Gets online users for a poker session.

  ## Examples

      iex> get_online_poker_users(poker.id)
      [%PokerUser{}, ...]

  """
  def get_online_poker_users(poker_id) do
    from(u in PokerUser,
      where: u.poker_id == ^poker_id and is_nil(u.left_at),
      order_by: [asc: u.joined_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a poker user by username within a specific poker session.
  """
  def get_poker_user_by_username(poker_id, username) do
    from(u in PokerUser, where: u.poker_id == ^poker_id and u.username == ^username)
    |> Repo.one()
  end

  # Private helper for broadcasting user updates
  defp broadcast_user_update(poker_id, message) do
    Phoenix.PubSub.broadcast(
      PlanningPoker.PubSub,
      "poker:#{poker_id}",
      message
    )
  end

  ## Voting Management

  @doc """
  Creates a voting for a poker session.

  ## Examples

      iex> create_voting(poker, %{title: "Story estimation"})
      {:ok, %Voting{}}

      iex> create_voting(poker, %{title: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_voting(%Poker{} = poker, attrs) do
    next_position = get_next_voting_position(poker.id)

    %Voting{}
    |> Voting.changeset(Map.merge(attrs, %{poker_id: poker.id, position: next_position}))
    |> Repo.insert()
    |> case do
      {:ok, voting} ->
        broadcast_voting_update(poker.id, {:voting_created, voting})
        {:ok, voting}

      error ->
        error
    end
  end

  @doc """
  Updates a voting.

  ## Examples

      iex> update_voting(voting, %{title: "New title"})
      {:ok, %Voting{}}

  """
  def update_voting(%Voting{} = voting, attrs) do
    voting
    |> Voting.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_voting} ->
        broadcast_voting_update(voting.poker_id, {:voting_updated, updated_voting})
        {:ok, updated_voting}

      error ->
        error
    end
  end

  @doc """
  Deletes a voting.

  ## Examples

      iex> delete_voting(voting)
      {:ok, %Voting{}}

  """
  def delete_voting(%Voting{} = voting) do
    case Repo.delete(voting) do
      {:ok, deleted_voting} ->
        broadcast_voting_update(voting.poker_id, {:voting_deleted, deleted_voting})
        {:ok, deleted_voting}

      error ->
        error
    end
  end

  @doc """
  Sets a decision for a voting and marks it as closed.

  ## Examples

      iex> set_voting_decision(voting, "5 story points")
      {:ok, %Voting{}}

  """
  def set_voting_decision(%Voting{} = voting, decision) do
    update_voting(voting, %{decision: decision})
  end

  @doc """
  Removes the decision from a voting, reopening it.

  ## Examples

      iex> remove_voting_decision(voting)
      {:ok, %Voting{}}

  """
  def remove_voting_decision(%Voting{} = voting) do
    update_voting(voting, %{decision: nil})
  end

  @doc """
  Gets votings for a poker session ordered by position.

  ## Examples

      iex> get_poker_votings(poker.id)
      [%Voting{}, ...]

  """
  def get_poker_votings(poker_id) do
    from(v in Voting, where: v.poker_id == ^poker_id, order_by: [asc: v.position])
    |> Repo.all()
  end

  @doc """
  Gets a single voting by id.

  ## Examples

      iex> get_voting(voting_id)
      %Voting{}

      iex> get_voting("unknown")
      nil

  """
  def get_voting(id), do: Repo.get(Voting, id)

  defp get_next_voting_position(poker_id) do
    from(v in Voting,
      where: v.poker_id == ^poker_id,
      select: max(v.position)
    )
    |> Repo.one()
    |> case do
      nil -> 1
      max_position -> max_position + 1
    end
  end

  defp broadcast_voting_update(poker_id, message) do
    Phoenix.PubSub.broadcast(
      PlanningPoker.PubSub,
      "poker:#{poker_id}",
      message
    )
  end
end
