defmodule CercleApi.APIV2.TagController do

  require Logger
  use CercleApi.Web, :controller

  alias CercleApi.Tag

  plug CercleApi.Plug.EnsureAuthenticated

  def index(conn, params) do
    CercleApi.Plug.current_user(conn)
    company = current_company(conn)

    q = Map.get(params, "q")
    query = from tag in Tag,
      where: tag.company_id == ^company.id

    if q do
      query = from tag in query,
        where: like(tag.name, ^"#{q}%")
    end

    tags = Repo.all(query)
    render(conn, "index.json", tags: tags)
  end

  def create(conn, %{"id" => _id, "name" => tag_name}) do
    CercleApi.Plug.current_user(conn)
    company = current_company(conn)

    tag = Repo.get_by(Tag, name: tag_name, company_id: company.d) ||
      Repo.insert!(%Tag{name: tag_name, company_id: company.id})
    render(conn, "show.json", tag: tag)
  end

  def update(conn, %{"id" => id, "tag" => tag_params}) do
    tag = Repo.get!(Tag, id)
    changeset = Tag.changeset(tag, tag_params)
    case Repo.update(changeset) do
      {:ok, tag} ->
        render(conn, "show.json", tag: tag)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CercleApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    tag = Repo.get!(Tag, id)
    Repo.delete!(tag)
    # send_resp(conn, :no_content, "") no method found to test this response
    json conn, %{status: 200}
  end
end
