defmodule CercleApi.Oauth.AuthorizationController do
  use CercleApi.Web, :controller
  plug Guardian.Plug.EnsureAuthenticated
  plug CercleApi.Plugs.CurrentUser
  plug :put_layout, "oauth.html"

  alias ExOauth2Provider.Authorization

  def new(conn, params) do
    current_resource_owner = Guardian.Plug.current_resource(conn)
    case Authorization.preauthorize(current_resource_owner, params) do
      {:ok, client, scopes} ->
        render(conn, "new.html", params: params, client: client, scopes: scopes)
      {:native_redirect, %{code: code}} ->
        redirect(conn, to: oauth_authorization_path(conn, :show, code))
      {:redirect, redirect_uri} ->
        redirect(conn, external: redirect_uri)
      {:error, error, status} ->
        conn
        |> put_status(status)
        |> render("error.html", error: error)
    end
  end

  #params = %{"_csrf_token" => "ICAwNDc9XGRbXQ5uWFhYDGBWKgptAAAAMwdqEm5Qkla40snA1dFgUg==", "_utf8" => "✓", "client_id" => "a63311608bba2a432438edf435351bc6", "redirect_uri" => "https://zapier.com/dashboard/auth/oauth/return/App66849API/", "response_type" => "code", "scope" => "", "state" => "1496733637.2716082"}
  def create(conn, params) do
    current_resource_owner = Guardian.Plug.current_resource(conn)
    current_resource_owner
    |> Authorization.authorize(params)
    |> redirect_or_render(conn)
  end

  def delete(conn, params) do
    current_resource_owner = Guardian.Plug.current_resource(conn)
    current_resource_owner
    |> Authorization.deny(params)
    |> redirect_or_render(conn)
  end

  def show(conn, %{"code" => code}) do
    render(conn, "show.html", code: code)
  end

  defp redirect_or_render({:redirect, redirect_uri}, conn) do
    redirect(conn, external: redirect_uri)
  end
  defp redirect_or_render({:native_redirect, payload}, conn) do
    json conn, payload
  end
  defp redirect_or_render({:error, error, status}, conn) do
    conn
    |> put_status(status)
    |> json(error)
  end

end
