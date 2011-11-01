# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel.define_request :OpenProject do
  
  parameter :file
  
  def execute(pars)
    raise(Errors::InvalidParameter, "'#{pars[:file]}' is not a file!") unless File.file?(pars[:file])
    
    project = PM::Project.load(pars[:file])
    Karfunkel.log_info("[#@sender] Loading project '#{project.name}'.")
    Karfunkel.projects << project
    
    answer :processing
    broadcast :load_project, :mapset_extraction => 0, :char_extraction => 0
    
    #TODO: Not sure--when the Command containing this Request gets GC’ed, is
    #this timer then eliminated...? If Karfunkel crashes with obscure
    #exceptions (which I have not seen yet), this may be the case...
    timer = EventMachine.add_periodic_timer(2) do
      if project.loaded?
        answer :finished
        broadcast :loaded_project, :name => project.name
        timer.cancel
      else
        broadcast :load_project, project.loading
      end
    end
  end
  
end
