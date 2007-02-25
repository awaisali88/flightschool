//
// schedule.js - client side code for painting scheduling reservation browser interface 
// @author - Lev Popov levpopov@mit.edu
//

DAY_START_HOUR = 7
DAY_END_HOUR = 23

// sets the date to be displayed on the schedule
function set_schedule_date(year,month,date,days_since_2000){

	start_day_number = days_since_2000
	end_day_number = start_day_number+num_days-1
	
	var day = new Date()
	day.setYear(year)
	day.setMonth(month-1) // javascript's amazing Date class has months starting with 0 
	day.setDate(date)
	
	schedule_date = dateToString(day)
	day.setDate(day.getDate()+num_days)
	next_schedule_date = dateToString(day)
	day.setDate(day.getDate()-2*num_days) 
	previous_schedule_date = dateToString(day)
	$('date').value = schedule_date
	$('trigger').value = schedule_date
	

	if(displaying_new_reservation_form){
		$('reservation_start_date').value = schedule_date
		$('reservation_end_date').value = schedule_date
		setStartDate();
		setEndDate();
	}
	
	day.setDate(day.getDate()+num_days)
	for(var i=0;i<num_days;i++){
		if(num_days<=7)
			$('date_label_'+i).innerHTML = day.formatDate('D, M j')
		else
			$('date_label_'+i).innerHTML = day.formatDate('D').substring(0,1)+day.formatDate(', j')
		day.setDate(day.getDate()+1) 
	}
}

// updates the schedule display with provided reservation data (JSON-formatted array of reservations)
function set_reservations(reservations){
	var graph = $('graph');//schedule drawing pane

	$$('.approved_booking_reservation_bar').each(function(bar){		Element.remove(bar);	})
	$$('.created_booking_reservation_bar').each(function(bar){		Element.remove(bar);	})
	$$('.approved_instructor_block_reservation_bar').each(function(bar){		Element.remove(bar);	})
	$$('.approved_aircraft_block_reservation_bar').each(function(bar){		Element.remove(bar);	})
	
	$A(reservations).each(function(r){				
		var start_d = r['start_days']
		var start_h = r['start_hour']
		if((start_d > end_day_number) || (start_d==(end_day_number) && start_h>DAY_END_HOUR)) return;
		if(start_d < start_day_number) start_d = start_day_number;
		if(start_h<DAY_START_HOUR) start_h=DAY_START_HOUR;
		if(start_h>DAY_END_HOUR) start_h=DAY_END_HOUR;
		
		var end_d = r['end_days']
		var end_h = r['end_hour']
		if((end_d < start_day_number) || (end_d==(start_day_number) && end_h<DAY_START_HOUR)) return;
		if(end_d > end_day_number) end_d = end_day_number;
		if(end_h<DAY_START_HOUR) end_h=DAY_START_HOUR;
		if(end_h>DAY_END_HOUR) end_h=DAY_END_HOUR;
				
		var left = (start_d-start_day_number)*width_per_day + (start_h-DAY_START_HOUR)*width_per_hour
		var right = (end_d-start_day_number)*width_per_day + (end_h-DAY_START_HOUR)*width_per_hour
		var width = right-left + 'px'	
		
		if(defined(r['aircraft_id']) && defined(tops['a'+r['aircraft_id']])){
			var abar = document.createElement('div');
		    abar.setAttribute("class",r['status']+"_"+r['reservation_type']+"_reservation_bar");
		    abar.setAttribute("className",r['status']+"_"+r['reservation_type']+"_reservation_bar");
		    abar.style.width = width;
			abar.style.left = label_width+left+'px';
	    	abar.style.top = tops['a'+r['aircraft_id']] + 'px'
	
			if(current_user==r['created_by'] || admin){
				abar.style.cursor = 'pointer'
				if(current_user==r['created_by'])
					abar.style.border = "2px solid green"
		    	abar.innerHTML = r['pilot']	
				abar.onclick = function(e){
					new Ajax.Updater('reservation_sidebar', '/reservation/edit?id='+r['id'], {asynchronous:true, evalScripts:true})
				}		
			}
				
    		graph.appendChild(abar);
		}
		
		if(defined(r['instructor_id']) && defined(tops['i'+r['instructor_id']])){
			var ibar = document.createElement('div');
		    ibar.setAttribute("class",r['status']+"_"+r['reservation_type']+"_reservation_bar");
		    ibar.setAttribute("className",r['status']+"_"+r['reservation_type']+"_reservation_bar");
		    ibar.style.width = width;
			ibar.style.left = label_width+left+'px';
	    	ibar.style.top = tops['i'+r['instructor_id']] + 'px'
	
			if(current_user==r['created_by'] || admin){
				ibar.style.cursor = 'pointer'
				if(current_user==r['created_by'])
					ibar.style.border = "2px solid green"
		    	ibar.innerHTML = r['pilot']	
				ibar.onclick = function(e){
					new Ajax.Updater('reservation_sidebar', '/reservation/edit?id='+r['id'], {asynchronous:true, evalScripts:true})
				}		
			}
	
    		graph.appendChild(ibar);
		}		
	})
	hide_loading_indicator();
}
