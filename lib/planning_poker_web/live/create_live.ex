defmodule PlanningPokerWeb.CreateLive do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Poker
  alias PlanningPokerWeb.Forms.CreatePokerForm

  def mount(_params, _session, socket) do
    changeset = CreatePokerForm.changeset(%CreatePokerForm{})

    {:ok,
     socket
     |> assign(:page_title, "Create Poker")
     |> assign(:form, to_form(changeset))
     |> assign(:preview_html, "")
     |> assign(:active_tab, "edit")}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("validate", %{"create_poker_form" => form_params}, socket) do
    changeset =
      %CreatePokerForm{}
      |> CreatePokerForm.changeset(form_params)
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
      %CreatePokerForm{}
      |> CreatePokerForm.changeset(%{})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("create", %{"create_poker_form" => form_params}, socket) do
    changeset = CreatePokerForm.changeset(%CreatePokerForm{}, form_params)

    if changeset.valid? do
      # Convert form data to poker creation params
      final_params =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> Map.from_struct()

      case Poker.create_poker(final_params) do
        {:ok, poker} ->
          {:noreply, push_navigate(socket, to: ~p"/poker/#{poker.id}")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to create poker. Please try again.")}
      end
    else
      {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("create", _params, socket) do
    changeset =
      %CreatePokerForm{}
      |> CreatePokerForm.changeset(%{})
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end
end
