defmodule PlanningPoker.Poker.PokerUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "poker_users" do
    field :username, :string
    field :joined_at, :utc_datetime
    field :left_at, :utc_datetime
    field :muted, :boolean, default: false

    belongs_to :poker, PlanningPoker.Poker.Poker, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(poker_user, attrs) do
    poker_user
    |> cast(attrs, [:username, :joined_at, :left_at, :muted, :poker_id])
    |> validate_required([:username, :joined_at, :poker_id])
    |> validate_length(:username, min: 1, max: 100)
    |> unique_constraint([:poker_id, :username])
    |> foreign_key_constraint(:poker_id)
  end

  @doc "Returns true if the user is currently online (left_at is nil)"
  def online?(%__MODULE__{left_at: nil}), do: true
  def online?(%__MODULE__{left_at: _}), do: false
end