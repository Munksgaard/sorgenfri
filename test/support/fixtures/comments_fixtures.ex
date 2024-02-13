defmodule Sorgenfri.CommentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sorgenfri.Comments` context.
  """

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        context: "some context",
        date: 42
      })
      |> Sorgenfri.Comments.create_comment()

    comment
  end
end
