defmodule PlanningPokerWeb.Forms.CreatePokerForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :description, :string
    field :card_type, :string, default: "fibonacci"
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:name, :description, :card_type])
    |> validate_required([:name])
    |> validate_inclusion(:card_type, ["fibonacci", "t-shirt"])
  end
end
