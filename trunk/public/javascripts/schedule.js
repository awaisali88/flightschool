//
// schedule.js - client side code for painting scheduling reservation browser interface 
// @author - Lev Popov levpopov@mit.edu
//


// sets the date to be displayed on the schedule
// server_time_zone is the offset in hours between server time zone and GMT
function set_schedule_date(date){
	fix_from = new Date();
	fix_from.setTime(date+7*60*60*1000)
	
	fix_to = new Date();
	fix_to.setTime(date+23*60*60*1000)
		
	var tmp = new Date()
	tmp.setTime(date+12*60*60*1000) //add 12 hours to make sure that we dont end up in a different day 
									//after time zone adjustment
	schedule_date = dateToString(tmp)
	tmp.setDate(tmp.getDate()+1)
	next_schedule_date = dateToString(tmp)
	tmp.setDate(tmp.getDate()-2)
	previous_schedule_date = dateToString(tmp)
	$('date').value = schedule_date
	$('trigger').value = schedule_date
	
	if(displaying_new_reservation_form){
		$('reservation_start_date').value = schedule_date
		$('reservation_end_date').value = schedule_date
		setStartDate();
		setEndDate();
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
		var start = new Date()
		start.setTime(r['start_int'])
		if(start > fix_to) return;
		if(start<fix_from) {start = fix_from}

		var end = new Date()
		end.setTime(r['end_int'])
		if(end < fix_from) return;
		if(end>fix_to) {end = fix_to}
		
		var width = width_per_hour*(end-start)/(60*60*1000) + 'px'
		var left = label_width+width_per_hour*(start-fix_from)/(60*60*1000) + 'px'
		
		if(defined(r['aircraft_id']) && defined(tops['a'+r['aircraft_id']])){
			var abar = document.createElement('div');
		    abar.setAttribute("class",r['status']+"_"+r['reservation_type']+"_reservation_bar");
		    abar.setAttribute("className",r['status']+"_"+r['reservation_type']+"_reservation_bar");
		    abar.style.width = width;
			abar.style.left = left;
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
			ibar.style.left = left;
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
