defmodule Docs.DocumentChannel do
  use Docs.Web, :channel
  alias Docs.Document

  def join("documents:" <> doc_id, params, socket) do
    send(self, {:after_join, params})
    {:ok, assign(socket, :doc_id, doc_id)}
  end

  def handle_info({:after_join, params}, socket) do
    doc = Repo.get(Document, socket.assigns.doc_id)
    last_id = params["last_message_id"]
    messages = Repo.all(
      from m in assoc(doc, :messages),
        order_by: [desc: m.inserted_at],
        select: %{id: m.id, body: m.body},
        where: m.id > ^last_id,
        limit: 100
    )
    push socket, "messages", %{messages: messages}
    {:noreply, socket}
  end

  def handle_in("text_change", %{"ops" => ops}, socket) do
    # broadcast to everyone BUT the sender
    broadcast_from! socket, "text_change", %{
      ops: ops
    }
    {:reply, :ok, socket}
  end

  def handle_in("save", params, socket) do
    Document
    |> Repo.get(socket.assigns.doc_id)
    |> Document.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, _document} -> 
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{reasons: changeset}}, socket}
    end
  end

  def handle_in("new_message", params, socket) do
    changeset =
      Document
      |> Repo.get(socket.assigns.doc_id)
      |> Ecto.Model.build(:messages)
      |> Message.changeset(params)

    case Repo.insert(changeset) do
      {:ok, msg} ->
        broadcast! socket, "new_message", %{body: params["body"]}
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, :error, %{reasons: changeset}}
    end
  end

end
