defmodule ScopedRepo do
  defmodule InvalidSpecificationException, do: defexception [:message]

  defmacro __using__(options) do
    scope_by = options[:scope_by]
    repo = options[:repo]

    if is_nil(scope_by) do
      raise InvalidSpecificationException, "You need to specify a schema to scope by. Pass a :scope option to use()"
    end

    if is_nil(repo) do
      raise InvalidSpecificationException, "You need to specify a repo for your app. Pass a :repo option to use()"
    end

    quote do
      Module.register_attribute __MODULE__, :scope_by, []
      Module.register_attribute __MODULE__, :repo, []
      @scope_by unquote(scope_by)
      @repo unquote(repo)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    function_headers() ++
    insert_functions_for(
      Module.get_attribute(env.module, :scope_by),
      Module.get_attribute(env.module, :repo)
    )
  end

  def function_headers do
    [
      quote do
        def insert(base, assoc_name,  params, opts \\ [])
      end,
      quote do
        def update(base, assoc_name, id, params, opts \\ [])
      end
    ]
  end

  def insert_functions_for(scope, repo) do
    Enum.flat_map scope.__schema__(:associations), fn (assoc_name) ->
      case scope.__schema__(:association, assoc_name) do
        %Ecto.Association.Has{cardinality: :many, related: relation} ->
          [
            defparamless(repo, :all, assoc_name),
            defparamless(repo, :delete_all, assoc_name),
            defparamless(repo, :one, assoc_name),
            defparamless(repo, :one!, assoc_name),
            defwithid(repo, :get, assoc_name),
            defwithid(repo, :get!, assoc_name),
            definsert(repo, :insert, assoc_name, relation),
            definsert(repo, :insert!, assoc_name, relation),
            defupdate(repo, :update, assoc_name, relation),
            defupdate(repo, :update!, assoc_name, relation),
          ]
        %Ecto.Association.Has{cardinality: :one, related: relation} ->
          [
            defparamless(repo, :one, assoc_name),
            defparamless(repo, :one!, assoc_name),
            definsert(repo, :insert, assoc_name, relation),
            definsert(repo, :insert!, assoc_name, relation),
            defupdate(repo, :update, assoc_name, relation),
            defupdate(repo, :update!, assoc_name, relation),
          ]
        _ ->
          []
      end
    end
  end

  defp defparamless(repo, func, assoc_name) do
    quote do
      def unquote(func)(base, unquote(assoc_name)) do
        base
        |> Ecto.assoc(unquote(assoc_name))
        |> unquote(repo).unquote(func)
      end
    end
  end

  defp defwithid(repo, func, assoc_name) do
    quote do
      def unquote(func)(base, unquote(assoc_name), id) do
        base
        |> Ecto.assoc(unquote(assoc_name))
        |> unquote(repo).unquote(func)(id)
      end
    end
  end

  defp definsert(repo, func, assoc_name, schema) do
    quote do
      def unquote(func)(base, unquote(assoc_name), params, opts) do
        changeset = opts[:changeset] || &unquote(schema).changeset/2
        base
        |> Ecto.build_assoc(unquote(assoc_name))
        |> changeset.(params)
        |> unquote(repo).unquote(func)
      end
    end
  end

  defp defupdate(repo, func, assoc_name, schema) do
    quote do
      def unquote(func)(base, unquote(assoc_name), id, params, opts) do
        changeset = opts[:changeset] || &unquote(schema).changeset/2
        base
        |> Ecto.build_assoc(unquote(assoc_name))
        |> unquote(repo).get!(id)
        |> changeset.(params)
        |> unquote(repo).unquote(func)
      end
    end
  end
end
