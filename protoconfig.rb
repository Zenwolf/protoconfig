##
# Copyright 2014 Matthew Jaquish
# Licensed under the Apache License, Version 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
# Represent the Universal Design Pattern of a collection of properties that can
# inherit from another collection of properties.
#
# NOTES:
# 1. Enforces keys as symbols to avoid string mutation problems. See:
#    convert_key, convert_keys, get, set.
#
# 2. You can look up property names as object methods and it will delegate to
#    the internal private property hash.
#
# 3. It assumes that any method call that ends with a "=" is a setter, and it
#    will set the value in the hash accordingly for that symbol.
#
# 4. Otherwise, it assumes a method call is a property getter and it will
#    return the value assigned to that symbol from the hash, or ask any
#    existing prototype to return a value if there is no local value.
#
# 5. It always returns nil if there is no value.
#
# Further reading:
# http://steve-yegge.blogspot.com/2008/10/universal-design-pattern.html
#

class ProtoConfig
  require 'json'

  attr_reader :proto

  def initialize(props = {}, proto = nil)
    @proto = proto
    @p = convert_keys(props || {})
  end

  ##
  # proto can be another ProtoConfig or nil.
  #
  def proto=(proto)
    if (proto.is_a? ProtoConfig) || proto.nil?
      @proto = proto
    else
      fail("The prototype must be a ProtoConfig or nil.")
    end
  end

  def has(name)
    @p.has_key? convert_key(name)
  end

  ##
  # Deletes a property from this config.
  #
  def delete(name)
    key = convert_key(name)
    return false unless has(key)
    @p.delete(key)
    true
  end

  ##
  # Convert this config to a standard hash format.
  #
  def to_hash
    @proto ? @proto.to_hash.merge(@p) : @p
  end

  ##
  # Convert this config to a standard JSON format.
  #
  def to_json
    to_hash.to_json
  end

  ##
  # This is used to identify property gets and sets to make it easier to use
  # and prevent the developer from having to use an unwieldy API like "get(key)"
  # or "set(key, val)". Relying on method_missing may be a bit slow, but these
  # objects shouldn't be used in any critical systems where preformance is
  # sensitive.
  #
  # It should be possible to make these perform better by dynamically creating
  # missing methods after the first call and then passing the message with
  # send().
  #
  def method_missing(symbol, *args, &block)
    key = symbol.to_s
    return set(key[0, key.length - 1].to_sym, args.first) if (key[-1].eql? '=')
    get(symbol)
  end

  ##
  # Make sure this object responds to the same kind of operations that
  # method_missing handles.
  #
  def respond_to?(symbol, priv = false)
    return true if super
    return true if has(symbol)
    return @proto.respond_to?(symbol, priv) if @proto
    # Basically, this can respond to anything since it will interpret it as a
    # property getter or setter if not already a property. This is probably
    # wrong, but it currently works for me.
    true
  end


  private

    def get(name)
      key = convert_key(name)
      result = @p[key]
      return @proto.send(key) if (result.nil? && @proto)
      result
    end

    def set(name, value)
      @p[convert_key(name)] = value
    end

    def convert_key(name)
      (name.is_a? Symbol) ? name : name.to_sym
    end

    def convert_keys(hash)
      hash.inject({}) do | memo, (k, v) |
        memo[convert_key(k)] = v
        memo
      end
    end

end
