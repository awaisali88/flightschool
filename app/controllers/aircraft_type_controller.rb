#####################################################################################
#
# AircraftTypeController provides functionality for editing aircraft types/classes
# The code is based on auto-generated scaffold.
# 
# Authors:: Lev Popov levpopov@mit.edu
# 
#####################################################################################

class AircraftTypeController < ApplicationController

  # redirect to list action below
  def index
     return unless has_permission :can_manage_aircraft
    @page_title = "Aircraft Types"
    list
    render :action => 'list'
  end

  #displays paginated list of all aircraft types 
  def list
    return unless has_permission :can_manage_aircraft
    @page_title = "Aircraft Types"
    @aircraft_types =  AircraftType.find :all ,:order=>'type_name'
  end

  # page with a form for adding new aircraft type
  def new
     return unless has_permission :can_manage_aircraft
    @page_title = "New Aircraft Type"
    @aircraft_type = AircraftType.new
  end

  # handles POST from "add new aircraft type" form, creating new aircraft type in the system
  def create
     return unless has_permission :can_manage_aircraft
    @aircraft_type = AircraftType.new(params[:aircraft_type])
    if @aircraft_type.save
      flash[:notice] = 'AircraftType was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

   # page with form for editing aircraft type properties
  def edit
     return unless has_permission :can_manage_aircraft
    @page_title = "Edit Aircraft Type"
    @aircraft_type = AircraftType.find(params[:id])
  end

  # handles POST from "edit aircraft type" form, updating aircraft type properties in the system
  def update
    return unless has_permission :can_manage_aircraft
    @aircraft_type = AircraftType.find(params[:id])
    if @aircraft_type.update_attributes(params[:aircraft_type])
      flash[:notice] = 'AircraftType was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
end
