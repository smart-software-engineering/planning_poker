defmodule PlanningPoker.Poker.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "games" do
    field :name, :string
    field :description, :string
    field :secret, :string
    field :moderator_email, :string

    has_many :votings, PlanningPoker.Poker.Voting, preload_order: [asc: :position]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :description, :secret, :moderator_email])
    |> validate_required([:name, :secret])
    |> validate_format(:moderator_email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
  end
end
