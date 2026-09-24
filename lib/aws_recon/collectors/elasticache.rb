# frozen_string_literal: true

#
# Collect ElastiCache resources
#
class ElastiCache < Mapper
  def collect
    resources = []

    #
    # describe_cache_clusters
    #
    @client.describe_cache_clusters.each_with_index do |response, page|
      log(response.context.operation_name, page)

      response.cache_clusters.each do |cluster|
        struct = OpenStruct.new(cluster.to_h)
        struct.type = 'cluster'
        struct.arn = cluster.arn

        resources.push(struct.to_h)
      end
    end

    #
    # describe_replication_groups
    #
    # Multi-AZ and automatic failover live on the group, not the clusters in it.
    #
    # Rescued because an exception here would discard the clusters collected above.
    #
    begin
      @client.describe_replication_groups.each_with_index do |response, page|
        log(response.context.operation_name, page)

        response.replication_groups.each do |group|
          struct = OpenStruct.new(group.to_h)
          struct.type = 'replication_group'
          struct.arn = group.arn

          resources.push(struct.to_h)
        end
      end
    rescue Aws::ElastiCache::Errors::ServiceError => e
      puts "Ignoring exception: '#{e.message}'\n"

      raise e if @options.quit_on_exception
    end

    resources
  end
end
