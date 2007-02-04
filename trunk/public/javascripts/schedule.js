function set_schedule_date(date){
	fix_from = new Date();
	fix_from.setTime(date)
	fix_from.setHours(7);
	fix_to = new Date();
	fix_to.setTime(date)
	fix_to.setHours(23);	
		
	tmp = new Date()
	tmp.setTime(date)
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

function set_reservations(reservations){
	var graph = $('graph');

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

		if(admin){
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


/*
<% @aircraft_reservations.each{|r|%>
		<% if tops["a#{r.aircraft_id}"].nil? then next end %>
 		<div id="abar<%=r.id%>" class="reservation_bar" 
		<% @start = r.time_start < @fixfrom ? @fixfrom: r.time_start %>
		<% @end = r.time_end > @fixto ? @fixto : r.time_end  %>
		<% if @start.hour < 7 then @start = Time.local(@start.year,@start.month,@start.day,7) end%>
		<% if @end.hour < 7 then @end = Time.local(@end.year,@end.month,@end.day,7) end%>
		<% left = ((@start-@fixfrom)/(24*60*60)).floor*width_per_day+(@start.hour-@fixfrom.hour)*width_per_hour + msie_pos_fix-1 %>
		<% right = ((@end-@fixfrom)/(24*60*60)).floor*width_per_day+(@end.hour-@fixfrom.hour)*width_per_hour + msie_pos_fix-1 %>
		<% width = right-left + msie_width_fix +1 %>		
		
	   	style="width:<%=width %>px; top:<%=tops["a#{r.aircraft_id}"].to_i+1+msie_height_fix%>px;
	   	    left: <%=label_width+left%>px;
			background:<%= r.status=="approved"? (r.reservation_type == 'booking' ? 'lightgreen' : 'tan') : 'yellow' %>;
	   	">
	   	<%= can_see_names ? r.creator.full_name.gsub(" ","&nbsp;") : (@user.full_name == r.creator.full_name ? r.creator.full_name.gsub(" ","&nbsp;") : '&nbsp;') %></div>
		
	 	<%= if can_approve_reservations? then draggable_element("abar"+r.id.to_s , :revert => true) end %>
 	<% } %>

*/
function draw_schedule(aircrafts,instructors,days){
    var graph = $('graph');
    var gw = graph.offsetWidth;
    var lw = 120;
    var hh = 20;
    var gh = hh;
    var type_h = 20;
    var air_h = 20;
    var width_per_hour = (gw-lw)/(days*16);//we only show 16 hours

    for(i=0;i<aircrafts.length;i++){
        gh += type_h+aircrafts[i][1].length*air_h;
    }
    //draw background
    for(i=0;i<days;i++){
        for(j=0;j<8;j++){
            var bar = document.createElement('div');
            bar.style.width=width_per_hour*2+"px";
            bar.style.height=gh+"px";
            bar.style.background= j%2==0 ? "#f0f5ff":"#d0e5ff" ;
            bar.style.position="absolute";
            bar.style.left = width_per_hour*2*(8*i+j)+lw+"px";
            if(j==0){ bar.style.borderLeft="1px solid black"}
            graph.appendChild(bar);
        }
    }    
    
    var offset=hh;
    //draw aircraft labels
    for(i=0;i<aircrafts.length;i++){
          //type name bar
          var bar = document.createElement('div');
          bar.setAttribute("class","type_label_over");
          bar.setAttribute("className","type_label_over");
          bar.style.width=gw+"px";
          bar.style.height=type_h+"px";
          bar.style.top = offset+"px";
          bar.innerHTML = aircrafts[i][0].attributes.type_name
          offset+=type_h;
          graph.appendChild(bar);

          //aircrafts
          for(j=0;j<aircrafts[i][1].length;j++){
          bar = document.createElement('div');
          bar.setAttribute("class","aircraft_name");
          bar.setAttribute("className","aircraft_name");
          bar.style.width=lw+"px";
          bar.style.height=air_h+"px";
          bar.style.top = offset+"px";
          bar.innerHTML = aircrafts[i][1][j].attributes.identifier
          graph.appendChild(bar);
          offset+=air_h;
          }
    }
    
    graph.style.height = gh+'px'  
}