# frozen_string_literal: true

require("graphql_queries")

module GraphQLRequestHelper
  include GraphQLQueries
  # Must set this to get thru robot filter
  def setup
    @headers = { "User-Agent" => "iPadApp" }
  end

  # Add a token if we have one
  def headers_with_auth(token)
    # puts("@headers.inspect")
    # puts(@headers.inspect)
    return @headers unless token

    headers = @headers
    headers["Authorization"] = "Bearer #{token}"
    headers
  end

  def graphql_path
    "/graphql"
  end

  # Parse the response body
  def json
    JSON.parse(response.body)
  end

  # Graphql request with the `query` and `variables` defaults.
  def do_graphql_request(user: nil, qry: nil, var: nil, token: nil)
    token ||= Token.new(user_id: user&.id,
                        in_admin_mode: user&.admin).encrypt_to_header

    post(graphql_path,
         params: {
           query: qry || query,
           variables: var || variables
         },
         headers: headers_with_auth(token))
  end

  # Give variables an empty default
  def variables
    {}
  end
end
