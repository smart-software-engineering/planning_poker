defmodule PlanningPokerWeb.CreateLive do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Poker
  alias PlanningPokerWeb.Forms.CreateGameForm

  def mount(_params, _session, socket) do
    changeset = CreateGameForm.changeset(%CreateGameForm{})

    {:ok,
     socket
     |> assign(:page_title, "Create Game")
     |> assign(:form, to_form(changeset))
     |> assign(:preview_html, "")
     |> assign(:active_tab, "edit")}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("validate", %{"create_game_form" => form_params}, socket) do
    changeset =
      %CreateGameForm{}
      |> CreateGameForm.changeset(form_params)
      |> Map.put(:action, :validate)

    preview_html =
      case form_params["description"] do
        desc when is_binary(desc) and desc != "" ->
          case Earmark.as_html(desc) do
            {:ok, html, _} -> html
            _ -> ""
          end

        _ ->
          ""
      end

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:preview_html, preview_html)}
  end

  def handle_event("validate", _params, socket) do
    changeset =
      %CreateGameForm{}
      |> CreateGameForm.changeset(%{})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("create", %{"create_game_form" => form_params}, socket) do
    changeset = CreateGameForm.changeset(%CreateGameForm{}, form_params)

    if changeset.valid? do
      # Convert form data to poker creation params
      data = Ecto.Changeset.apply_changes(changeset)
      
      # Set default secret if all_moderators is true
      final_params = 
        data
        |> Map.from_struct()
        |> then(fn params ->
          if params.all_moderators do
            Map.put(params, :secret, generate_default_secret())
          else
            Map.put(params, :secret, params.secret)
          end
        end)

      case Poker.create_poker(final_params) do
        {:ok, game} ->
          {:noreply, push_navigate(socket, to: ~p"/poker/#{game.id}")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to create game. Please try again.")}
      end
    else
      {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("create", _params, socket) do
    changeset =
      %CreateGameForm{}
      |> CreateGameForm.changeset(%{})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  defp generate_default_secret do
    # Generate a 24-character secure secret with mixed case, numbers, and safe special chars
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*-_+="

    for _ <- 1..24, into: "" do
      <<Enum.random(String.to_charlist(chars))>>
    end
  end
end
