require 'helper'

class TestSoulmate < Test::Unit::TestCase
  
  def setup
    Soulmate::Loader.new('venues').delete_all
  end
  
  def test_integration_can_load_values_and_query
    load_initial_items
    
    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term('stad', :limit => 5)
    
    assert_equal 3, results.size
    assert_equal 'Angel Stadium', results[0]['term']
  end
  
  def test_integration_can_add_values_and_query
    items = parse_items_from_samples_file('another_venue.json')

    items_loaded = Soulmate::Loader.new('venues').add_items(items)
    assert_equal 1, items_loaded
    
    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term('Ann Ar', :limit => 5)

    assert_equal 1, results.size
    assert_equal 'Ann Arbor', results[0]['term']

  end

  def test_delete
    items = load_initial_items
    
    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term(items.last['term'], :limit => 5)

    assert_equal 1, results.size

    
    Soulmate::Loader.new('venues').delete(items.last)
    
    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term(items.last['term'], :limit => 5)

    assert_equal 0, results.size
  end
  
  
  def test_delete_by_id
    load_initial_items
    
    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term('Dodger', :limit => 5)

    assert_equal 1, results.size
    
    
    Soulmate::Loader.new('venues').delete_by_id(1)

    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term('Dodger', :limit => 5)

    assert_equal 0, results.size
  end

    
  protected
    def load_initial_items
      items = parse_items_from_samples_file('venues.json')
      
      items_loaded = Soulmate::Loader.new('venues').load(items)
      assert_equal 5, items_loaded
      
      items
    end
  
    def parse_items_from_samples_file(file)
      items = []

      lines = File.open(File.expand_path(File.dirname(__FILE__)) + '/samples/' + file, "r")
      lines.each_line do |line|
        items << JSON.parse(line)
      end

      items
    end
    
end
