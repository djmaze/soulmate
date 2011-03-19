module Soulmate

  class Loader < Base

    def load(items)
      delete_all
      
      add_items(items)
    end

    def add_items(items)
      items_loaded = 0
      items.each_with_index do |item, i|
        if add_item(item)
          items_loaded += 1 
          puts "added #{i} entries" if i % 100 == 0 and i != 0
        end
      end

      items_loaded
    end
    
    def add_item(item)
      id    = item["id"]
      term  = item["term"]
      score = item["score"]

      if id and term
        # store the raw data in a separate key to reduce memory usage
        Soulmate.redis.hset(database, id, JSON.dump(item))

        prefixes_for_phrase(term).each do |p|
          Soulmate.redis.sadd(base, p) # remember this prefix in a master set
          Soulmate.redis.zadd("#{base}:#{p}", score, id) # store the id of this term in the index
        end

        true
      else
        false
      end
    end
    
    def delete(item)
      id    = item["id"]
      term  = item["term"]
      score = item["score"]
      
      if id and term
        Soulmate.redis.hdel(database, id)
        
        prefixes_for_phrase(term).each do |p|
          Soulmate.redis.srem(base, p)
          Soulmate.redis.zrem("#{base}:#{p}", id)
        end
        
        # TODO Expire cachekey?

      end
    end
    
    def delete_by_id(id)
      item = JSON.parse(Soulmate.redis.hget(database, id))
      delete(item)
    end
    
    def delete_all
      # delete the sorted sets for this type
      # wrap in multi/exec?
      phrases = Soulmate.redis.smembers(base)
      phrases.each do |p|
        Soulmate.redis.del("#{base}:#{p}")
      end
      Soulmate.redis.del(base)

      # Redis can continue serving cached requests for this type while the reload is
      # occuring. Some requests may be cached incorrectly as empty set (for requests
      # which come in after the above delete, but before the loading completes). But
      # everything will work itself out as soon as the cache expires again.

      # delete the data stored for this type
      Soulmate.redis.del(database)
    end
    
  end
end