defmodule PlanningPokerWeb.Forms.CreateGameForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :description, :string
    field :secret, :string
    field :moderator_email, :string
    field :card_type, :string, default: "fibonacci"
    field :all_moderators, :boolean, default: true
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:name, :description, :secret, :moderator_email, :card_type, :all_moderators])
    |> validate_required([:name, :moderator_email, :all_moderators])
    |> validate_inclusion(:card_type, ["fibonacci", "t-shirt"])
    |> validate_format(:moderator_email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_secret_conditionally()
  end

  defp validate_secret_conditionally(changeset) do
    all_moderators = get_field(changeset, :all_moderators)
    
    if all_moderators do
      # When all_moderators is true, we don't require the secret field
      changeset
    else
      # When all_moderators is false, validate the secret as required
      changeset
      |> validate_required([:secret])
      |> validate_length(:secret, min: 16, max: 100)
      |> validate_format(:secret, ~r/[a-z]/, message: "must contain at least one lowercase letter")
      |> validate_format(:secret, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
      |> validate_format(:secret, ~r/[0-9]/, message: "must contain at least one number")
      |> validate_format(:secret, ~r/[!@#$%^&*\-_+=]/,
        message: "must contain at least one special character (!@#$%^&*-_+=)"
      )
      |> validate_format(:secret, ~r/^[a-zA-Z0-9!@#$%^&*\-_+=]+$/,
        message: "contains invalid characters. Only letters, numbers, and !@#$%^&*-_+= are allowed"
      )
    end
  end
end
