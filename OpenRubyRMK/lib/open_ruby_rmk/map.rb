#!/usr/bin/env ruby
#Encoding: UTF-8

=begin
This file is part of OpenRubyRMK. 

Copyright © 2010 OpenRubyRMK Team

OpenRubyRMK is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OpenRubyRMK is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.
=end

module OpenRubyRMK
  
  #This class represents a map for the OpenRubyRMK. It has nothing to 
  #do with the Map class used inside the created games, beside the fact 
  #that both use the same file format. 
  #
  #The format of the map files is as follows: 
  #They're binary files serialized with Ruby's +Marshal+ module. Inside 
  #is a hash of this form stored: 
  #  {
  #    :name => "the name of the map", 
  #    :mapset => "name of the mapset", 
  #    :table => a_4dimensional_array, 
  #    :parent => the_id_of_the_parent_map_or_zero
  #  }
  #where the 4-dimensional array is simply the description of the three-dimensional 
  #map table (X, Y and Z coordinates) plus the coordinates of the mapset fields, which are 
  #stored as an array of form <tt>[x, y]</tt>. 
  #For example, 
  #  ary[4, 2, 0] #=> [4, 7]
  #tells us that for the field at (4|2) at the ground layer the mapset's field at position 
  #(4|7) should be used. 
  #
  #You may noticed that the ID of the map isn't contained in the serialized hash. 
  #That's because it is simply determined from the file's name, which should be 
  #like this: 
  #  <id_of_map>.bin
  #For instance: 
  #  3.bin
  #For the map with ID 3. 
  class Map
    include Wx
    
    #The unique ID of a map. Cannot be changed. 
    attr_reader :id
    attr_reader :parent
    attr_reader :children_ids
    #The mapset used to display this map. 
    attr_accessor :mapset
    
    ##
    # :attr_acessor: name
    #The name of this map. If no name is set or it is empty, 
    #a stringified version of it's ID will be returned. 
    
    @maps = []
    
    #Returns the next available map ID. 
    def self.next_free_id
      ids = @maps.map(&:id)
      1.upto(1.0/0.0) do |n| #that's 1 upto infinity / 0 is used for the root element
        break(n) unless ids.include?(n)
      end
    end
    
    #A list of all map IDs that are currently in use. 
    def self.used_ids
      @maps.map(&:id)
    end
    
    #An array containg all maps that have been created or loaded. 
    def self.maps
      @maps
    end
    
    #true if the given ID is used by some map. 
    def self.id_in_use?(id)
      used_ids.include?(id)
    end
    
    def self.maps_dir=(dir)
      @maps_dir = Pathname.new(dir)
    end
    
    def self.maps_dir
      raise(ArgumentError, "No map dir specified!") if @maps_dir.nil?
      @maps_dir
    end
    
    #Loads a map object from a file. The filename is detected by 
    #using OpenRubyRMK.project_maps_dir and the given ID. Raises an ArgumentError 
    #if no file is found. 
    #See this class's documentation for a description of the file format. 
    def self.load(id)
      filename = Pathname.new(OpenRubyRMK.project_maps_dir + "#{id}.bin")
      raise(ArgumentError, "Map not found: #{id}!") unless filename.file?
      hsh = filename.open("rb"){|f| Marshal.load(f)}
      id = filename.basename.to_s.to_i #Filenames are of form "3.bin" and #to_i stops at the ".". 
      
      obj = allocate
      obj.instance_eval do
        @id = id
        @name = hsh[:name]
        @mapset = hsh[:mapset]
        @table = hsh[:table]
        @parent = self.class.from_id(hsh[:parent])
        @parent.children_ids << @id unless @parent.nil? #Map.from_id returns nil if there's no parent
        @children_ids = []
        
      end
      @maps << obj
      obj
    end
    
    #Deletes the map with the given ID from the list of remembered maps, 
    #plus all children's IDs (recursively, so a children's children etc. also 
    #gets removed). 
    #After a call to this method you shouldn't use any map object with this 
    #ID or a child ID anymore. 
    #Returns the deleted map's ID which can now be used as an available ID. 
    def self.delete(id)
      #Recursively delete all children maps
      @maps.children_ids.each do |child_id|
        delete(child_id)
      end
      #Delete this map and remove it's file
      @maps.delete_if{|map| map.id == id}
      OpenRubyRMK.project_maps_dir.join("#{id}.bin").delete rescue nil #If the file doesn't exist it can't be deleted
      id
    end
    
    #Reconstructs a map object by it's ID. Note that this ID isn't the 
    #map's object ID, but an internal ID used to uniquely identify a map. 
    #In contrast to the object ID, it persists across program sessions. 
    #Within a single session, you'll get the absolute same object back, 
    #that is, this equals true: 
    #  map = Map.new(112, ...)
    #  map2 = Map.from_id(112)
    #  map.equal?(map)
    #That's possible since the Map class automatically remembers all 
    #created Map objects. If you want to "free" an ID, you have to explicitely 
    #delete a map by calling it's #delete! method or calling Map.delete which 
    #does the same, it just takes an ID instead of a Map object. 
    def self.from_id(id)
      return nil if id == 0 #No parent
      m = @maps.find{|map| map.id == id}
      raise(ArgumentError, "A map with ID #{id} doesn't exist!") if m.nil?
      m
    end
    
    #Creates a new Map object. Pass in the map's ID, name, initial dimensions 
    #and, if you want to create a child map, the parent map's ID (pass 0 for no parent). 
    #
    #This method remembers the maps you create in a class instance variable @maps, 
    #allowing you to reconstruct a map object just by it's ID without struggling around 
    #with ObjectSpace. 
    def initialize(id, name, mapset, width, height, depth, parent = 0) #0 is no valid map ID, i.e. it's the root element
      raise(ArgumentError, "Parent ID #{parent} doesn't exist!") if parent.nonzero? and !self.class.id_in_use?(parent)
      raise(ArgumentError, "The ID #{id} is already in use!") if self.class.id_in_use?(id)
      @id = id
      self.class.maps << self
      @name = name.to_str
      @mapset = mapset
      @table = Array.new(width){Array.new(height){Array.new(depth){[0, 0]}}} #(0|0) should always be transparent on the mapset
      @parent = self.class.from_id(parent)
      @parent.children_ids << @id unless @parent.nil? #Map.from_id returns nil if there's no parent
      @children_ids = []
      #Remember the map
      self.class.maps << self
    end
    
    #Returns an array containing all parent IDs of this map, 
    #i.e. the parent's ID, the parent's parent's ID, etc. 
    #The form of the array is descenending, i.e. the direct parent 
    #can be found at the end of the hash, whereas the parent that 
    #doesn't have a parent itself resides at the array's beginning. 
    def parent_ids
      return [] if @parent == 0
      parents = []
      parent = @parent
      until parent.nil?
        parents << parent.id
        parent = parent.parent
      end
      parents.reverse
    end
    
    #Destroys this map by removing it from the list of remembered maps. 
    #Don't use the map object after a call to this method anymore. 
    def delete!
      self.class.delete(self.id)
    end
    
    #Returns the field of the associated mapset that is used 
    #at the given position. It's returned as a two-element 
    #array of form
    #  [x, y]
    #where +x+ indicates the column index (0-based) and 
    #+y+ indicates the row index (0-based, too). For example, 
    #if 
    #  my_map[2, 4, 0]
    #returns <tt>[3, 7]</tt>, we get to know, that at position 
    #(2|4) in the height 0 (that is the ground layer) the field 
    #from the mapset was used, that can be found at position 
    #(3|7) on the mapset. 
    def [](x, y, z)
      @table[x][y][z]
    end
    
    #Sets the tile that should be used at the given position. 
    #+tile_pos+ is a two-element array of form
    #  [x, y]
    #. For an explanation, see #[]. 
    def []=(x, y, z, tile_pos)
      @table[x][y][z] = tile_pos.to_ary
    end
    
    #See accessor. 
    def name # :nodoc:
      @name.nil? || @name.empty? ? @id.to_s : @name
    end
    
    #See accessor. 
    def name=(str) # :nodoc
      @name = str.to_s
    end
    
    #Human-readable description of form 
    #  <OpenRubyRMK::GUI::Map ID: <map_id> Size: <width>x<height>x<depth>>
    #. 
    def inspect
      "<#{self.class} ID: #{@id} Size: #{@table.size}x#{@table[0].size}x#{@table[0][0].size}>"
    end
    
    #Saves this map to a file in OpenRubyRMK.project_maps_dir. See this class's documentation 
    #for a description of the file format. 
    def save
      hsh = {
        :name => name, #@name may be unset
        :mapset => @mapset, 
        :table => @table, 
        :parent => @parent.nil? ? 0 : @parent.id #0 means there's no parent
      }
      OpenRubyRMK.projects_maps_dir.join("#{@id}.bin").open("wb"){|f| Marshal.dump(hsh, f)}
    end
    
  end
  
end