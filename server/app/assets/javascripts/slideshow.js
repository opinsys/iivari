function updateSlideData(url, cache) {
    if(cache == true) {
        // jquery-offline handles transport errors
        // NOTE: if offline (no network), but server is localhost, json data is not requested!
        $.retrieveJSON(url, function(json, status, attributes) {
            console.log("updateSlideData status: "+status+", received "+json.length+" JSON objects");
            if (status == "cached") {
                //console.log("slide data cached at "+attributes.cachedAt);
            }
            if (status != "notmodified") {
                //console.log("received new slide data");
                slideData.json = json;
                window.applicationCache.update();
            }
        });
    }
    else {
        $.ajax({
          url: url,
          dataType: 'json',
          cache: false,
          success: function(data, status, attributes) {
              console.log("updateSlideData status: "+status+", received "+data.length+" JSON objects");
              slideData.json = data;
          },
          error: function(req, error) {
              console.warn("Warning: XHR status: "+req.status+ ": "+error);
          }
        });
    }
}

function showNextSlide(repeat) {
    // wait one second if slideData.json is not defined yet
    if ( slideData.json == null ) {
	setTimeout(showNextSlide, 1000,repeat);
	return;
    }

    var counter = 0;
    var newSlideFound = 0;

    while (!newSlideFound && counter < slideData.json.length) {
	counter = counter + 1;
	
	if ( slideNumber > slideData.json.length - 1 ) {
  	    slideNumber = 0;	
	}

	// When repeat value is false then request is come from Iivari management user interface.
	// Check slide's timer configuration and status only if repeat is true
	if (repeat == true) {
	    // If slide status is not active or time of show not match, continue to next slide
	    if ( checkSlideTimerAndStatus(slideData.json[slideNumber]) == false ) {
		slideNumber = slideNumber + 1;
	    } else {
		newSlideFound = 1;
            }
	} else {
	    newSlideFound = 1;
	}
    }
    
    if (newSlideFound == 0) {
	setTimeout(showNextSlide, 5000, repeat);
    } else { 
	
	oldslide = $('.slide');

	var newslide = document.createElement('div');
	$(newslide).addClass('slide');
	$(newslide).append(slideData.json[slideNumber]["slide_html"]);
	$(newslide).appendTo('body');

	// fit iframe height to visible screen
	iframeResize();

	$(oldslide).hide();
	$(newslide).show();
	$(oldslide).remove();

	slide_delay = slideData.json[slideNumber]["slide_delay"] * 1000;
	slideNumber = slideNumber + 1;
	if (repeat == true) {
	    setTimeout(showNextSlide, slide_delay, repeat);
	}
    }
}

function checkTime(i)
{
    if (i<10) 
	{i="0" + i}
    return i;
}

function checkSlideTimerAndStatus(slide) {
    if (slide.status == false) {
	return false
    }

    var timers = slide.timers

    if (timers.length == 0) {
	return true;
    }
    else {
        /* Slide timers check.
        
        Returns true if any of given timers are active now.
        
        FIXME: if the client is on without a web access for years,
        all timers most likely be off next year -> unneeded support requests.
        Maybe the timer should accept information without specific years.

        Times are in UTC.
        
         */
	var now = new Date();
	for ( i = 0; i < timers.length; i++ ) {
	    if ( ! timers[i]["weekday_" + now.getDay()] ) {
		continue;
	    }

        // range start_datetime..end_datetime the period of days when timer is active
	    var start_datetime = new Date(timers[i].start_datetime);
	    var end_datetime = new Date(timers[i].end_datetime);

        // range raw_start_time..raw_end_time the hours each day the timer is active
	    var raw_start_time = new Date(timers[i].start_time);
	    var raw_end_time = new Date(timers[i].end_time);

        // range start_time..end_time is the hours the timer is active today
	    var start_time = new Date( now.getFullYear(),
		now.getMonth(),
		now.getDate(),
		raw_start_time.getHours(),
		raw_start_time.getMinutes() );
	    var end_time = new Date( now.getFullYear(),
		now.getMonth(),
		now.getDate(),
		raw_end_time.getHours(),
		raw_end_time.getMinutes() );

        /*
        console.log("timer active between "+
            start_datetime.getFullYear() +"-"+
            (start_datetime.getMonth()+1) +"-"+
            start_datetime.getDate() +
            " - "+
            end_datetime.getFullYear() +"-"+
            (end_datetime.getMonth()+1) +"-"+
            end_datetime.getDate() +
            " at "+
            raw_start_time.getHours() + ":"+
            raw_start_time.getMinutes() +
            " - "+
            raw_end_time.getHours() + ":"+
            raw_end_time.getMinutes()
            );
        */

        // start_datetime or end_datetime may not be set, that's ok
	    if ( (start_datetime.toString() == "Invalid Date" || now > start_datetime ) &&
		 ( end_datetime.toString() == "Invalid Date" || now < end_datetime) ) {
            // now is somewhere in between start_datetime and end_datetime

		if ( now > start_time && now < end_time ) {
            // hours match, at least one timer is active
            console.log("timer matches");
		    return true;
		}
	    }
	}
    }
    return false;
}


/* Fix iframe height when screen is rotated with xrandr */
function iframeResize() {
    var _iframe = $("iframe");
    if (_iframe) {
        var new_height = $(window).height() - $(".footer_container").height();
        $(_iframe).height(new_height);
    }
}

/* Resize iframe on window resize event */
$(window).resize(function() {
    iframeResize();
});
