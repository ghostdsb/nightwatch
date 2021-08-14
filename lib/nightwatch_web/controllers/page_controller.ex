defmodule NightwatchWeb.PageController do
  use NightwatchWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
