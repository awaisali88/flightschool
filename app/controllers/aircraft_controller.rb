#####################################################################################
#
# AircraftController provides functionality for managing aircraft, including 
# adding/(soft)deleting aircraft, and editing their properties. 
# The code is based on auto-generated scaffold.
# 
# Authors:: Lev Popov levpopov@mit.edu
# 
#####################################################################################

class AircraftController < ApplicationController

  # redirect to list action below
  def index
    return unless has_permission :can_manage_aircraft
    @page_title = "Aircraft"
    list
    render :action => 'list'
  end

  #displays paginated list of all aircraft 
  def list
    return unless has_permission :can_manage_aircraft
    @page_title = "Aircraft"
    @offices = Office.find :all
    @aircrafts = Aircraft.find :all , 
      :select => "aircrafts.id,aircrafts.office,aircrafts.deleted,aircrafts.prioritized,aircrafts.identifier,aircraft_types.type_name", 
      :joins=>'inner join aircraft_types on aircraft_types.id = aircrafts.aircraft_type',
      :order=>'aircrafts.deleted,aircraft_types.type_name'
  end


  # page with form for adding new aircraft
  def new
    return unless has_permission :can_manage_aircraft
    @page_title = "New Aircraft"
    @aircraft = Aircraft.new
  end

  # handles POST from "add new aircraft" form, creating new aircraft in the system
  def create
    return unless has_permission :can_manage_aircraft
    @aircraft = Aircraft.new(params[:aircraft])
    if @aircraft.save
      flash[:notice] = 'Aircraft was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  # page with form for editing aircraft properties
  def edit
    return unless has_permission :can_manage_aircraft
    @page_title = "Edit Aircraft Information"
    @aircraft = Aircraft.find(params[:id])
  end

  # handles POST from "edit aircraft" form, updating aircraft properties in the system
  def update
     return unless has_permission :can_manage_aircraft
    Aircraft.transaction do
      @aircraft = Aircraft.find(params[:id])
      @res = @aircraft.update_attributes(params[:aircraft])
    end
    if @res
      flash[:notice] = 'Aircraft was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  # soft deletes an aircraft
  def delete
     return unless has_permission :can_manage_aircraft
    Aircraft.transaction do
      a = Aircraft.find(params[:id])
      a.deleted = true
      @res = a.save
    end
    if @res
      flash[:notice] = "Aircraft Flagged as Deleted"
      redirect_to :back
    else
      flash[:warning] = "Error Deleting Aircraft"
      redirect_to :back
    end  
  end
  
  # undo for soft delete of an aircraft
  def undelete
     return unless has_permission :can_manage_aircraft
    Aircraft.transaction do
      a = Aircraft.find(params[:id])
      a.deleted = false
      @res = a.save
    end
    if @res
      flash[:notice] = "Aircraft Flagged as Not Deleted"
      redirect_to :back
    else
      flash[:warning] = "Error Un-Deleting Aircraft"
      redirect_to :back
    end   
  end
  
end
