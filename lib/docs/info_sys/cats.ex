defmodule Docs.InfoSys.Cats do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    send(self, :request)
    :random.seed(:os.timestamp())
    {:ok, opts}
  end

  def handle_info(:request, opts) do
    if String.contains?(opts[:expr], "cat") do
      img_url = random_cat()
      send(opts[:client_pid], {:result, self, %{ score: 100, img_url: img_url}})
    else
      {:noresult, self} 
    end

    {:stop, :shutdown, opts}
  end

  defp random_cat() do
    [
      "https://animalswithsunglasses.files.wordpress.com/2010/12/sunglasscat2.jpg",
      "https://adorablay.files.wordpress.com/2007/02/0415.jpg",
      "https://adorablay.files.wordpress.com/2007/02/cat-hat.jpg"
    ] |> Enum.random
  end
end
