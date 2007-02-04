##############################################################################
#
# Controller with functionality for keeping track of aircraft maintenance
# schedules, allowing administrators to create maintenance counters that
# display how long until a particular aircraft will need to be taken
# out for service. The counters are stored in MaintenanceDate ActiveRecord
# instances.
# Adapted from scaffold code.
#
# Authors:: Lev Popov levpopov@mit.edu
#
##############################################################################

class MaintenanceController < ApplicationController

  # shows all existing counters with their expiration values and remaining tach
  # until service values
  def index
    return unless has_permission :can_manage_aircraft
    list
    render :action => 'list'
  end

  
  # shows all existing counters with their expiration values and remaining tach
  # until service values
  def list
   return unless has_permission :can_manage_aircraft
    @page_title = "Aircraft Maintenance"
    @maintenance_date_pages, @maintenance_dates = paginate :maintenance_dates, :per_page => 10
  end

  # A page for adding a new maintenance counter
  def new
   return unless has_permission :can_manage_aircraft
    @page_title = "New Aircraft Maintenance Counter"
    @maintenance_date = MaintenanceDate.new
  end

  # responds to 'create new counter' request, adding a counter to the database
  def create
   return unless has_permission :can_manage_aircraft
    @maintenance_date = MaintenanceDate.new(params[:maintenance_date])
    if @maintenance_date.save
      flash[:notice] = 'Created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  # Page for editing maintenance counter details
  def edit
   return unless has_permission :can_manage_aircraft
    @page_title = "Edit Aircraft Maintenance Counter"
    @maintenance_date = MaintenanceDate.find(params[:id])
  end

  # responds to 'edit counter' requests, saving changes to the database
  def update
   return unless has_permission :can_manage_aircraft
    @maintenance_date = MaintenanceDate.find(params[:id])
    if @maintenance_date.update_attributes(params[:maintenance_date])
      flash[:notice] = 'Updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  # permanently removes a counter
  def destroy
   return unless has_permission :can_manage_aircraft
    MaintenanceDate.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
