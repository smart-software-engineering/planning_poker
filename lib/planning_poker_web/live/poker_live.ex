defmodule PlanningPokerWeb.PokerLive do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Poker
  alias PlanningPokerWeb.Forms.{JoinPokerForm, CreatePokerForm, VotingForm}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    case params do
      %{"id" => id} ->
        handle_join_poker(id, socket)

      %{} ->
        handle_create_poker(socket)
    end
  end

  # All handle_event functions grouped together
  def handle_event(
        "validate",
        %{"create_poker_form" => form_params},
        %{assigns: %{mode: :create}} = socket
      ) do
    changeset =
      %CreatePokerForm{}
      |> CreatePokerForm.changeset(form_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event(
        "validate",
        %{"join_poker_form" => form_params},
        %{assigns: %{mode: :join}} = socket
      ) do
    changeset =
      %JoinPokerForm{}
      |> JoinPokerForm.changeset(form_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("create_poker", %{"create_poker_form" => form_params}, socket) do
    changeset = CreatePokerForm.changeset(%CreatePokerForm{}, form_params)

    case changeset.valid? do
      true -> handle_valid_poker_creation(changeset, socket)
      false -> {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("identify_user", %{"join_poker_form" => form_params}, socket) do
    %{poker: poker} = socket.assigns
    changeset = JoinPokerForm.changeset(%JoinPokerForm{}, form_params)

    case changeset.valid? do
      true -> handle_valid_user_join(changeset, poker, socket)
      false -> {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("toggle_session_state", _params, socket) do
    %{poker: poker} = socket.assigns

    result =
      if PlanningPoker.Poker.closed?(poker) do
        PlanningPoker.Poker.reopen_poker(poker)
      else
        PlanningPoker.Poker.close_poker(poker)
      end

    case result do
      {:ok, updated_poker} ->
        status = if PlanningPoker.Poker.closed?(updated_poker), do: "closed", else: "reopened"

        {:noreply,
         socket
         |> assign(:poker, updated_poker)
         |> put_flash(:info, "Session #{status} successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update session state")}
    end
  end

  def handle_event("leave_session", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  def handle_event("toggle_mute", _params, socket) do
    %{poker_id: poker_id, user_name: user_name} = socket.assigns

    case Poker.toggle_mute_poker_user(poker_id, user_name) do
      {:ok, _user} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to toggle mute: #{inspect(reason)}")}
    end
  end

  def handle_event("add_voting", _params, socket) do
    voting_form = to_form(VotingForm.changeset(%VotingForm{}))
    
    {:noreply, 
     socket
     |> assign(:show_voting_form, true)
     |> assign(:voting_form, voting_form)}
  end

  def handle_event("cancel_voting", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_voting_form, false)
     |> assign(:voting_form, nil)}
  end

  def handle_event("validate_voting", %{"voting_form" => form_params}, socket) do
    changeset =
      %VotingForm{}
      |> VotingForm.changeset(form_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :voting_form, to_form(changeset))}
  end

  def handle_event("save_voting", %{"voting_form" => form_params}, socket) do
    %{poker: poker} = socket.assigns
    changeset = VotingForm.changeset(%VotingForm{}, form_params)

    case changeset.valid? do
      true ->
        data = Ecto.Changeset.apply_changes(changeset)
        attrs = %{title: data.title, link: data.link}
        
        case Poker.create_voting(poker, attrs) do
          {:ok, _voting} ->
            {:noreply,
             socket
             |> assign(:show_voting_form, false)
             |> assign(:voting_form, nil)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to save voting")}
        end

      false ->
        {:noreply, assign(socket, :voting_form, to_form(changeset))}
    end
  end

  def handle_event("set_decision", %{"voting_id" => voting_id, "decision" => decision}, socket) do
    voting = Poker.get_voting(voting_id)
    
    case Poker.set_voting_decision(voting, String.trim(decision)) do
      {:ok, _voting} ->
        {:noreply, socket}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to set decision")}
    end
  end

  def handle_event("remove_decision", %{"voting_id" => voting_id}, socket) do
    voting = Poker.get_voting(voting_id)
    
    case Poker.remove_voting_decision(voting) do
      {:ok, _voting} ->
        {:noreply, socket}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove decision")}
    end
  end

  def terminate(_reason, socket) do
    if socket.assigns[:user_identified] && socket.assigns[:user_name] do
      Poker.leave_poker_user(socket.assigns.poker_id, socket.assigns.user_name)
    end

    :ok
  end

  def handle_info({:user_joined, user_name}, socket) do
    users = Poker.get_poker_users(socket.assigns.poker_id)

    if user_name == socket.assigns[:user_name] do
      {:noreply, assign(socket, :users, users)}
    else
      {:noreply,
       socket
       |> assign(:users, users)
       |> put_flash(:info, "#{user_name} joined")}
    end
  end

  def handle_info({:user_left, user_name}, socket) do
    users = Poker.get_poker_users(socket.assigns.poker_id)

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, "#{user_name} left")}
  end

  def handle_info({:user_mute_changed, user_name, muted}, socket) do
    users = Poker.get_poker_users(socket.assigns.poker_id)
    status = if muted, do: "muted", else: "unmuted"

    flash_message =
      if user_name == socket.assigns.user_name do
        "You are now #{status}"
      else
        "#{user_name} is now #{status}"
      end

    {:noreply,
     socket
     |> assign(:users, users)
     |> put_flash(:info, flash_message)}
  end

  def handle_info({:voting_created, _voting}, socket) do
    updated_poker = Poker.get_poker(socket.assigns.poker.id)
    {:noreply, assign(socket, :poker, updated_poker)}
  end

  def handle_info({:voting_updated, _voting}, socket) do
    updated_poker = Poker.get_poker(socket.assigns.poker.id)
    {:noreply, assign(socket, :poker, updated_poker)}
  end

  def handle_info({:voting_deleted, _voting}, socket) do
    updated_poker = Poker.get_poker(socket.assigns.poker.id)
    {:noreply, assign(socket, :poker, updated_poker)}
  end

  # Private helper functions
  defp handle_join_poker(id, socket) do
    case Poker.get_poker(id) do
      nil ->
        {:noreply, push_patch(socket, to: ~p"/poker")}

      poker ->
        Phoenix.PubSub.subscribe(PlanningPoker.PubSub, "poker:#{id}")

        user_identified = socket.assigns[:user_identified] || false
        user_name = socket.assigns[:user_name]

        {:noreply,
         socket
         |> assign(:page_title, poker.name)
         |> assign(:poker_id, id)
         |> assign(:poker, poker)
         |> assign(:poker_url, url(~p"/poker/#{id}"))
         |> assign(:user_identified, user_identified)
         |> assign(:user_name, user_name)
         |> assign(:users, poker.poker_users)
         |> assign(:mode, :join)
         |> assign(:form, to_form(JoinPokerForm.changeset(%JoinPokerForm{})))
         |> assign(:show_voting_form, false)
         |> assign(:voting_form, nil)}
    end
  end

  defp handle_create_poker(socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Create Poker")
     |> assign(:mode, :create)
     |> assign(:form, to_form(CreatePokerForm.changeset(%CreatePokerForm{})))}
  end

  defp handle_valid_poker_creation(changeset, socket) do
    data = Ecto.Changeset.apply_changes(changeset)

    with {:ok, poker} <- Poker.create_poker(%{name: data.name, card_type: data.card_type}),
         {:ok, _user} <- Poker.join_poker_user(poker, data.username) do
      {:noreply,
       socket
       |> assign(:user_identified, true)
       |> assign(:user_name, data.username)
       |> push_patch(to: ~p"/poker/#{poker.id}")
       |> put_flash(:info, "Welcome to your new poker session, #{data.username}!")}
    else
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create and join poker session")}
    end
  end

  defp handle_valid_user_join(changeset, poker, socket) do
    data = Ecto.Changeset.apply_changes(changeset)
    user_name = String.trim(data.name)

    case Poker.join_poker_user(poker, user_name) do
      {:ok, _user} ->
        users = Poker.get_poker_users(poker.id)

        {:noreply,
         socket
         |> assign(:user_identified, true)
         |> assign(:user_name, user_name)
         |> assign(:users, users)
         |> put_flash(:info, "Welcome, #{user_name}!")}

      {:error, %Ecto.Changeset{errors: [username: _]}} ->
        {:noreply, put_flash(socket, :error, "Username already taken")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to join poker")}
    end
  end
end