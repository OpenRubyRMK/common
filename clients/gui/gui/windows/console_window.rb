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
  
  module GUI
    
    module Windows
      
      #The window used to display OpenRubyRMKonsole. 
      class ConsoleWindow < Wx::Frame
        include Wx
        
        def initialize(parent = nil)
          super(parent, title: "OpenRubyRMKonsole", size: Size.new(660, 400))
          self.background_colour = NULL_COLOUR
          
          @console = Controls::RMKonsole.new(self, main: OpenRubyRMKonsole::Main)
          
          #Make sure the extra command's output goes to the right direction, i.e. the console control. 
          OpenRubyRMKonsole.output = @console.stdout
        end
        
      end #ConsoleWindow
      
    end #Windows
    
  end #GUI
  
end #OpenRubyRMK