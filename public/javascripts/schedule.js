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
	    var bar = document.createElement('div');
	    bar.setAttribute("class",r['status']+"_"+r['reservation_type']+"_reservation_bar");
	    bar.setAttribute("className",r['status']+"_"+r['reservation_type']+"_reservation_bar");

		var start = new Date()
		start.setTime(r['start_int'])
		if(start > fix_to) return;
		if(start<fix_from) {start = fix_from}

		var end = new Date()
		end.setTime(r['end_int'])
		if(end < fix_from) return;
		if(end>fix_to) {end = fix_to}


		
		bar.style.width = width_per_hour*(end-start)/(60*60*1000) + 'px'
		bar.style.left = label_width+width_per_hour*(start-fix_from)/(60*60*1000) + 'px'
		bar.style.top = '300px'

		if(current_user==r['created_by'] || admin){
			bar.style.cursor = 'pointer'
			if(current_user==r['created_by'])
				bar.style.border = "2px solid green"
	    	bar.innerHTML = r['pilot']	
			bar.onclick = function(e){
				new Ajax.Updater('reservation_sidebar', '/reservation/edit?id='+r['id'], {asynchronous:true, evalScripts:true})
			}		
		}		
		
		if(defined(r['aircraft_id']) && defined(tops['a'+r['aircraft_id']])){
	    	bar.style.top = tops['a'+r['aircraft_id']] + 'px'
    		graph.appendChild(bar);
		}
		if(defined(r['instructor_id']) && defined(tops['i'+r['instructor_id']])){
	    	bar.style.top = tops['i'+r['instructor_id']] + 'px'
    		graph.appendChild(bar);
		}		
	})
	hide_loading_indicator();
}
