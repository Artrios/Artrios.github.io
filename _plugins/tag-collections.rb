#!/usr/bin/env ruby

require "jekyll-archives"
require "jekyll"

module Jekyll
    module Archives
        class Archives
            alias_method :old_tags, :tags

            def collection_tags(collection_name)
                hash = Hash.new { |h, key| h[key] = [] }
                @site.collections[collection_name].docs.each do |p|
                    p.data["tags"]&.each { |t| hash[t] << p }
                end
                hash.each_value { |posts| posts.sort! }
                hash
            end

            def tags
                collections_to_tag = @config['collections']

                merged_tags = @site.post_attr_hash("tags")
                collections_to_tag.each { |collection|
                    merged_tags = merged_tags.merge(collection_tags(collection)) { |key, v1, v2| [v1,v2].flatten }
                }
                merged_tags
            end
        end
    end
end

