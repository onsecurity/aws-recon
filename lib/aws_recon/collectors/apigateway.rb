# frozen_string_literal: true

#
# Collect API Gateway resources
#
class APIGateway < Mapper
  #
  # Returns an array of resources.
  #
  def collect
    resources = []

    #
    # get_rest_apis
    #
    @client.get_rest_apis.each_with_index do |response, page|
      log(response.context.operation_name, page)

      response.items.each do |api|
        struct = OpenStruct.new(api.to_h)
        struct.type = 'api'
        struct.arn = api.id

        # get_authorizers
        struct.authorizers = @client.get_authorizers({ rest_api_id: api.id }).items.map(&:to_h)

        # get_stages
        struct.stages = @client.get_stages({ rest_api_id: api.id }).item.map(&:to_h)

        # get_models
        struct.models = @client.get_models({ rest_api_id: api.id }).items.map(&:to_h)

        # get_resources
        #
        # embed: methods is required for resource_methods to carry anything.
        # Without it the API returns the method names with empty bodies -
        # {"POST" => {}} - so authorization_type is absent and a method with
        # IAM auth is indistinguishable from an unauthenticated one. Verified
        # against a live REST API: the same call with the embed returns
        # authorization_type, api_key_required and the integration.
        struct.resources = @client.get_resources({ rest_api_id: api.id, embed: ['methods'] }).items.map(&:to_h)

        resources.push(struct.to_h)
      end
    end

    # get_domain_names
    @client.get_domain_names.each_with_index do |response, page|
      log(response.context.operation_name, page)

      response.items.each do |domain|
        struct = OpenStruct.new(domain.to_h)
        struct.type = 'domain'
        struct.arn = domain.domain_name

        resources.push(struct.to_h)
      end
    end

    resources
  end
end
