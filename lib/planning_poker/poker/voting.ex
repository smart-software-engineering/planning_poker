defmodule PlanningPoker.Poker.Voting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votings" do
    field :title, :string
    field :link, :string
    field :description, :string
    field :decision, :string
    field :votes, {:array, :map}, default: []
    field :position, :integer

    belongs_to :game, PlanningPoker.Poker.Game, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(voting, attrs) do
    voting
    |> cast(attrs, [:title, :link, :description, :decision, :votes, :position, :game_id])
    |> validate_required([:title, :position, :game_id])
    |> validate_length(:decision, max: 100)
    |> foreign_key_constraint(:game_id)
  end
end
