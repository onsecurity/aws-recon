# frozen_string_literal: true

#
# Collect WAFv2 resources
#
class WAFV2 < Mapper
  #
  # Returns an array of resources.
  #
  # TODO: resolve scope (e.g. CLOUDFRONT supported?)
  #
  def collect
    resources = []

    #
    # list_web_acls
    #
    # %w[CLOUDFRONT REGIONAL].each do |scope|
    %w[REGIONAL].each do |scope|
      @client.list_web_acls({ scope: scope }).each_with_index do |response, page|
        log(response.context.operation_name, page)

        response.web_acls.each do |acl|
          struct = OpenStruct.new(acl.to_h)
          struct.type = 'web_acl'

          params = {
            name: acl.name,
            scope: scope,
            id: acl.id
          }

          # get_web_acl
          @client.get_web_acl(params).each do |r|
            struct.arn = r.web_acl.arn
            struct.details = r.web_acl
          end

          # list_resources_for_web_acl
          @client.list_resources_for_web_acl({ web_acl_arn: acl.arn }).each do |r|
            struct.resources = r.resource_arns
          end

          resources.push(struct.to_h)
        end
      end
    end

    resources
  end
end
