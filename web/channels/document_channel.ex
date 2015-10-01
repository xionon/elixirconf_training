defmodule Docs.DocumentChannel do
  use Docs.Web, :channel

  def join("documents:" <> doc_id, _params, socket) do
    {:ok, assign(socket, :doc_id, doc_id)}
  end

  def handle_in("text_change", %{"ops" => ops}, socket) do
    # broadcast to everyone BUT the sender
    broadcast_from! socket, "text_change", %{
      ops: ops
    }
    {:reply, :ok, socket}
  end

end
