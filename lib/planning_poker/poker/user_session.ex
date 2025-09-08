defmodule PlanningPoker.Poker.UserSession do
  @moduledoc """
  Schema for storing user sessions that survive server restarts.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_sessions" do
    field :poker_id, :binary_id
    field :username, :string
    field :token, :string
    field :last_seen_at, :utc_datetime
    field :created_at, :utc_datetime

    timestamps()
  end

  def changeset(user_session, attrs) do
    user_session
    |> cast(attrs, [:poker_id, :username, :token, :last_seen_at, :created_at])
    |> validate_required([:poker_id, :username, :token])
    |> unique_constraint([:poker_id, :username])
  end
end
