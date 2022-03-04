defmodule Ueberauth.Strategy.Notion do
  use Ueberauth.Strategy,
    oauth2_module: Ueberauth.Strategy.Notion.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the notion authentication page.

  To customize the scope (permissions) that are requested by notion include
  them as part of your url:

      "/v1/oauth/authorize"
  """

  def handle_request!(conn) do
    params =
      []
      |> with_state_param(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [params]))
  end

  @doc """
  Handles the callback from Notion.

  When there is a failure from Notion the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Notion is
  returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      put_private(conn, :notion_token, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Notion
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:notion_user, nil)
    |> put_private(:notion_token, nil)
  end

  @doc """
  Includes the credentials from the Notion response.
  """
  def credentials(conn) do
    token = conn.private.notion_token

    %Credentials{
      token: token.access_token
    }
  end

  def uid(conn) do
    Map.from_struct(conn.private.notion_token)
    |> get_in([:other_params, "bot_id"])
  end

  @doc """
  Stores the raw information (including the token) obtained from the Notion
  callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: conn.private.notion_token.other_params
    }
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
