
function show_loading_indicator(parent){
    text = document.createTextNode('Loading...')
    indicator = document.createElement('div')
	indicator.className = 'loading_indicator'
    indicator.style.color = 'white'
    indicator.style.fontWeight = 'bold'
    indicator.style.margin = 'auto'
    indicator.appendChild(text)
    indicator.style.background = 'green'
    indicator.style.display = 'inline'
    indicator.style.position = 'absolute'
    indicator.style.top = '0px'
    indicator.style.right = '0px'    
    indicator.style.width = '100%'
    indicator.style.textAlign = 'center'
    $(parent).appendChild(indicator)
}

function hide_loading_indicator(){
	$$('.loading_indicator').each(function(e){Element.remove(e)});
}

function sortFunc(a, b) {
    var value1 = a.optText.toLowerCase();
    var value2 = b.optText.toLowerCase();
    if (value1 > value2) return(1);
    if (value1 < value2) return(-1);
    return(0);
}

/*function sortSelect(selectToSort){
	sortSelect(selectToSort,0)
}
*/
function sortSelect(selectToSort,skip) {
    // copy options into an array
    var myOptions = [];
    for (var i=skip; i<selectToSort.options.length; i++) {
        myOptions[i-skip] = { optText:selectToSort.options[i].text, optValue:selectToSort.options[i].value };
    }

    myOptions.sort(sortFunc);

    // copy sorted options from array back to select box
    selectToSort.options.length = skip;
    for (var i=0; i<myOptions.length; i++) {
        selectToSort.options[selectToSort.options.length]=(new Option(myOptions[i].optText,myOptions[i].optValue));
    }
}

function makeSelected(selectField,optionValue){
	for(i=0;i<selectField.options.length;i++)
    {
            selectField.options[i].selected = false
    }
	for(i=0;i<selectField.options.length;i++)
    {
        if(selectField.options[i].value == optionValue){
            selectField.options[i].selected = true
			return;
		}
    }
}

function selectFirst(selectField){
    selectField.options[0].selected = "selected"	
}

function dateToString(date){
	var year = date.getFullYear().toString()
	var month = (date.getMonth()+1).toString()
	var day = date.getDate().toString()
	return year+'-'+(month.length<2 ? '0' : '')+month+'-'+(day.length<2 ? '0' : '')+day
}

function defined(o){
	return (typeof o != "undefined")
}
//adapted from prototype.js code - this selector allows only doing
//matching on part of the displayed item
function autocomplete_selector(instance) {
    var ret       = []; // Beginning matches
    var partial   = []; // Inside matches
    var entry     = instance.getToken();
    var count     = 0;

    for (var i = 0; i < instance.options.array.length &&  
      ret.length < instance.options.choices ; i++) { 

      var elem = instance.options.array[i][2];
      var elemid = instance.options.array[i][0];	 
	  var before = instance.options.array[i][1];
	  var after = instance.options.array[i][3];	
      var foundPos = instance.options.ignoreCase ? 
        elem.toLowerCase().indexOf(entry.toLowerCase()) : 
        elem.indexOf(entry);

      while (foundPos != -1) {
        if (foundPos == 0 && elem.length != entry.length) { 
          ret.push("<li id=\""+elemid+"\">"+before+"<strong>" + elem.substr(0, entry.length) + "</strong>" + 
            elem.substr(entry.length) + after + "</li>");
          break;
        } else if (entry.length >= instance.options.partialChars && 
          instance.options.partialSearch && foundPos != -1) {
          if (instance.options.fullSearch || /\s/.test(elem.substr(foundPos-1,1))) {
            partial.push("<li id=\""+elemid+"\">" + before+ elem.substr(0, foundPos) + "<strong>" +
              elem.substr(foundPos, entry.length) + "</strong>" + elem.substr(
              foundPos + entry.length) + after+"</li>");
            break;
          }
        }

        foundPos = instance.options.ignoreCase ? 
          elem.toLowerCase().indexOf(entry.toLowerCase(), foundPos + 1) : 
          elem.indexOf(entry, foundPos + 1);

      }
    }
    if (partial.length)
      ret = ret.concat(partial.slice(0, instance.options.choices - ret.length))
    return "<ul>" + ret.join('') + "</ul>";
  }

function notNaN(n){
	return !isNaN(n)
}

function setElemClass(elem, classname)
{
	elem.className = classname
}

// returns whether the strings corresponding to year,month, and day compose a valid date
function validate_date(year,month,day){
	var date = new Date(parseInt(year),parseInt(month)-1,parseInt(day));		
	return date.getFullYear()==year && date.getMonth()==(month-1) && date.getDate() == day;
}

function activate_on_load(field){
	if (window.addEventListener) {
        window.addEventListener("load", function () { 	Field.activate($(field));	 }, false);
    } else if (window.attachEvent) {
        window.attachEvent('on' + "load", function () { 	Field.activate($(field));	 });
    }
}

function color_table(table){
	t = $(table)
	for(i=0;i<t.rows.length;i++)
		t.rows[i].className = i%2==0 ? 'even_row' : 'odd_row'
}

function quickpick_fix_selects(aircraft_type,instructor){
    for(i=0;i<document.forms['quickpick_form'].reservation_aircraft_type.options.length;i++)
    {
        if(document.forms['quickpick_form'].reservation_aircraft_type.options[i].value == aircraft_type)
            document.forms['quickpick_form'].reservation_aircraft_type.options[i].selected = "selected"
    }
  
    for(i=0;i<document.getElementById('quickpick_instructor_select').options.length;i++)
    {
        if(document.getElementById('quickpick_instructor_select').options[i].value == instructor)
           document.getElementById('quickpick_instructor_select').options[i].selected = "selected"
    }
    
}

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



// from popup.js - this section needs cleaning

function popup(evt) {
    var el = Event.element(evt);
    var result = window.open(el.href, 'rg_popup', 'scrollbars=yes, location=no, resizable=no, width=550,height=310'); 
    if (result != null) { Event.stop(evt); }
}
function apply_popup(el_or_id) {
    var el = $(el_or_id);
    if (el.tagName == 'A') {
        Event.observe(el, 'click', popup, false);        
    } else {
        /* recurse */
        $A(el.childNodes).each(apply_popup);
    }
}

/* Form.Element.setValue("fieldname/id","valueToSet") */
Form.Element.setValue = function(element,newValue) {
    element_id = element;
    element = $(element);
    if (!element){element = document.getElementsByName(element_id)[0];}
    if (!element){return false;}
    var method = element.tagName.toLowerCase();
    var parameter = Form.Element.SetSerializers[method](element,newValue);
}

Form.Element.SetSerializers = {
  input: function(element,newValue) {
    switch (element.type.toLowerCase()) {
      case 'submit':
      case 'hidden':
      case 'password':
      case 'text':
        return Form.Element.SetSerializers.textarea(element,newValue);
      case 'checkbox':
      case 'radio':
        return Form.Element.SetSerializers.inputSelector(element,newValue);
    }
    return false;
  },

  inputSelector: function(element,newValue) {
    fields = document.getElementsByName(element.name);
    for (var i=0;i<fields.length;i++){
      if (fields[i].value == newValue){
        fields[i].checked = true;
      }
    }
  },

  textarea: function(element,newValue) {
    element.value = newValue;
  },

  select: function(element,newValue) {
    var value = '', opt, index = element.selectedIndex;
    for (var i=0;i< element.options.length;i++){
      if (element.options[i].value == newValue){
        element.selectedIndex = i;
        return true;
      }        
    }
  }
}

function unpackToForm(data){
   for (i in data){
     Form.Element.setValue(i,data[i].toString());
   }
}
