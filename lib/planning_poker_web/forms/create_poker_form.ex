defmodule PlanningPokerWeb.Forms.CreatePokerForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :description, :string
    field :moderator_email, :string
    field :card_type, :string, default: "fibonacci"
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:name, :description, :moderator_email, :card_type])
    |> validate_required([:name, :moderator_email])
    |> validate_inclusion(:card_type, ["fibonacci", "t-shirt"])
    |> validate_format(:moderator_email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
  end
end
