defmodule NightwatchWeb.WebhookController do
  @moduledoc """
  Handlers for apis regarding Goals
  """
  use NightwatchWeb, :controller

  @doc """
  """
  def femo(conn, params) do
    params |> IO.inspect()
    json(conn, %{
      success: true,
      code: 200,
      version: "v1",
      data: params
    })
  end

  # defp send_error_resp(reason, conn) do
  #   json(conn, ApiUtils.generate_response(false, "v1", %{reason: reason}))
  # end
end
