//
// From Lightbox JS
// getPageScroll()
// Returns array with x,y page scroll values.
// Core code from - quirksmode.org
//
function getPageScroll(){

	var yScroll;
	var xScroll;

	if (self.pageYOffset) {
		yScroll = self.pageYOffset;
	} else if (document.documentElement && document.documentElement.scrollTop){	 // Explorer 6 Strict
		yScroll = document.documentElement.scrollTop;
	} else if (document.body) {// all other Explorers
		yScroll = document.body.scrollTop;
	}
	if (self.pageXOffset) {
		xScroll = self.pageXOffset;
	} else if (document.documentElement && document.documentElement.scrollLeft){	 // Explorer 6 Strict
		xScroll = document.documentElement.scrollLeft;
	} else if (document.body) {// all other Explorers
		xScroll = document.body.scrollLeft;
	}

	arrayPageScroll = new Array(xScroll,yScroll) 
	return arrayPageScroll;
}



//
// From Lightbox JS
// getPageSize()
// Returns array with page width, height and window width, height
// Core code from - quirksmode.org
// Edit for Firefox by pHaez
//
function getPageSize(){
	
	var xScroll, yScroll;
	
	if (window.innerHeight && window.scrollMaxY) {	
		xScroll = document.body.scrollWidth;
		yScroll = window.innerHeight + window.scrollMaxY;
	} else if (document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
		xScroll = document.body.scrollWidth;
		yScroll = document.body.scrollHeight;
	} else { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
		xScroll = document.body.offsetWidth;
		yScroll = document.body.offsetHeight;
	}
	
	var windowWidth, windowHeight;
	if (self.innerHeight) {	// all except Explorer
		windowWidth = self.innerWidth;
		windowHeight = self.innerHeight;
	} else if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
		windowWidth = document.documentElement.clientWidth;
		windowHeight = document.documentElement.clientHeight;
	} else if (document.body) { // other Explorers
		windowWidth = document.body.clientWidth;
		windowHeight = document.body.clientHeight;
	}	
	
	// for small pages with total height less then height of the viewport
	if(yScroll < windowHeight){
		pageHeight = windowHeight;
	} else { 
		pageHeight = yScroll;
	}

	// for small pages with total width less then width of the viewport
	if(xScroll < windowWidth){	
		pageWidth = windowWidth;
	} else {
		pageWidth = xScroll;
	}


	arrayPageSize = new Array(pageWidth,pageHeight,windowWidth,windowHeight) 
	return arrayPageSize;
}

function position_overlay(){
    var sizes = getPageSize();
    var scroll = getPageScroll();

    var width = 800;
    var height = 400;
   		
    $('overlay').style.top = (scroll[1] + ((sizes[3] - height) / 2) + 'px');
    $('overlay').style.left = (((sizes[0] - width) / 2) + 'px');
    
}

function update_document_body(id){
    $('image_value_field').value = id;
    if( $('document_body')==null) return;
    $('document_body').value = $('document_body').value + '!/image/show/'+ id +'!\n';
    new Effect.Highlight('document_body');
    
     
}


function image_upload_setup(){

$('UploadStatus').innerHTML='Upload starting...'; 
document.uploadStatus = new Ajax.PeriodicalUpdater('UploadStatus','/image/upload_status',
    Object.extend({ asynchronous:true, 
                    evalScripts:true, 
                    onComplete:function(request){
                            $('UploadStatus').innerHTML='Upload finished.';
                            document.uploadStatus = null;
                            new Ajax.Request('/image/upload', {asynchronous:true, evalScripts:true})
                     }
                  },
                  {decay:1.1,frequency:2.0}));                  
return true
}

// Code from http://www.diplok.com/1ppl/html/article077.html
function getAbsoluteLeft(objectId) {
	// Get an object left position from the upper left viewport corner
	// Tested with relative and nested objects
	o = document.getElementById(objectId)
	oLeft = o.offsetLeft            // Get left position from the parent object
	while(o.offsetParent!=null) {   // Parse the parent hierarchy up to the document element
		oParent = o.offsetParent    // Get parent object reference
		oLeft += oParent.offsetLeft // Add parent left position
		o = oParent
	}
	// Return left postion
	return oLeft
}

// Code from http://www.diplok.com/1ppl/html/article077.html
function getAbsoluteTop(objectId) {
	// Get an object top position from the upper left viewport corner
	// Tested with relative and nested objects
	o = document.getElementById(objectId)
	oTop = o.offsetTop            // Get top position from the parent object
	while(o.offsetParent!=null) { // Parse the parent hierarchy up to the document element
		oParent = o.offsetParent  // Get parent object reference
		oTop += oParent.offsetTop // Add parent top position
		o = oParent
	}
	// Return top position
	return oTop
}

function dist(a,b){
    tmp = (b-a)/(1000*60*60)
    return tmp > 0 ? tmp : 0
}


var master_schedule_start;
var master_schedule_end;
var master_schedule_adata;
var master_schedule_idata;

function add_reserved_blocks(start,end,aircraft_data,instructor_data){
    master_schedule_start = start
    master_schedule_end = end
    master_schedule_adata = aircraft_data
    master_schedule_idata = instructor_data
    
    if (window.addEventListener) {
        window.addEventListener("load", function () { repaint_blocks() }, false);
	} else if (window.attachEvent) {
	   window.attachEvent('on' + "load", function () { repaint_blocks() });
	}
}

function repaint_blocks(){
    start = master_schedule_start 
    end = master_schedule_end 
    aircraft_data = master_schedule_adata 
    instructor_data = master_schedule_idata 
    
    start = new Date(start)
    end = new Date(end)
    
    
    if (isMSIE())
     var MSIE_border_fix =  2
    else MSIE_border_fix =  0

    var left_offset = 100
    var top_offset = 17
    
    var total_width = 585;
    var width_per_hour = total_width / dist(start,end) 
        
    var adata = eval(aircraft_data)
    var idata = eval(instructor_data)
    for(i=0;i<adata.length;i++){
	    bar = $('abar'+adata[i][0])
	    bar.style.position = 'absolute'
	    bar.style.top = getAbsoluteTop('aircraft'+adata[i][1])+'px'
	    bar.style.left = getAbsoluteLeft('graph')+left_offset+dist(start,new Date(adata[i][2]))*width_per_hour+'px'	    
	    bar.style.width = MSIE_border_fix-2+((new Date(adata[i][3])-new Date(adata[i][2]))/(1000*60*60))*width_per_hour+'px'
    }
    for(i=0;i<idata.length;i++){
	    bar = $('ibar'+adata[i][0])
	    bar.style.position = 'absolute'
	    bar.style.top = getAbsoluteTop('instructor'+idata[i][1])+'px'
	    bar.style.left = getAbsoluteLeft('graph')+left_offset+dist(start,new Date(idata[i][2]))*width_per_hour+'px'	    
	    bar.style.width = MSIE_border_fix-2+((new Date(idata[i][3])-new Date(idata[i][2]))/(1000*60*60))*width_per_hour+'px'
    }
    
    for(i=1;i<=(end-start)/(60*60*1000*6);i++){
        bar=$('vbar'+i)
	    bar.style.position = 'absolute'
	    bar.style.top = getAbsoluteTop('graph')-top_offset+'px'
	    bar.style.left = getAbsoluteLeft('graph')+left_offset+(i-1)*width_per_hour*6+'px'	    
	    bar.style.width = MSIE_border_fix+width_per_hour*6+'px'
	    bar.style.height = Element.getDimensions('graph').height+top_offset+'px'
	    bar.style.background = i%2==0 ? "#f0f5ff" : "#d0e5ff"
        bar.style.borderTop = "2px solid black"
        bar.style.borderBottom = "1px solid black"
        if(i%4==1){
            bar.style.borderLeft = "2px solid black"
        }
        if(i%4==0){
            bar.style.borderRight = "2px solid black"
        }
        switch(i%4){
            case 1:  bar.innerHTML="0"; break;
            case 2:  bar.innerHTML="6"; break;
            case 3:  bar.innerHTML="12"; break;
            case 0:  bar.innerHTML="18"; break;
        }
       
    }
    
    document.getElementsByClassName('type_label_over').each(function(label){
        under = 'under'+label.id.substring(4)
        label.style.position='absolute'
        label.style.top = getAbsoluteTop(under)+'px'
        label.style.left = getAbsoluteLeft(under)+'px'
        label.style.width = MSIE_border_fix+left_offset+width_per_hour*dist(start,end)+'px'
        
    })
}

function isMSIE(){
   detect =  navigator.userAgent.toLowerCase();
   return detect.indexOf('msie') + 1;
}


