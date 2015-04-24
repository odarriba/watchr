var chart = null;
var chart_config = {};
var chart_last_id = "";

function chartStart(config) {
	config = config || {};

    config.live = config.live || true;

	// Check if the container is defined
	if (config == {})
		return;

	$('#'+config.container).highcharts({
        chart: {
            type: 'spline',
            zoomType: 'x'
        },
        title: {
            text: 'Results of '+config.name
        },
        subtitle: {
            text: 'Executed every '+config.interval+' seconds.'
        },
        xAxis: {
            type: 'datetime',
            dateTimeLabelFormats: { // don't display the dummy year
                month: '%e. %b',
                year: '%b'
            },
            title: {
                text: 'Date'
            }
        },
        yAxis: {
            title: {
                text: config.resume
            },
            min: 0
        },
        tooltip: {
            headerFormat: '<b>{point.y:.4f}</b><br>',
            pointFormat: '{point.x:%H:%M:%S - %d/%m/%Y}'
        },

        plotOptions: {
            spline: {
                marker: {
                    enabled: false
                }
            }
        },

        series: [{
            name: config.name+' service',
            // Define the data points. All series have a dummy year
            // of 1970/71 in order to be compared on the same x axis. Note
            // that in JavaScript, months start at 0 for January, 1 for February etc.
            data: [
            ]
        }]
    });

    config.chart = $('#'+config.container).highcharts();

    if (config.live)
        chartLive(config);
}

function chartLive(config) {
    url = config.url || window.location+"/data.json";

    if (config.last_id != "") {
        var call_url = url + "?last=" + config.last_id;
    }
    else {
        var call_url = url;
    }

    $.getJSON(call_url).success(function(data){
        for (var i = 0; i < data.length; i++) {
            data[i].date[2]--; // Correct month number

            // Create date object
            var date = Date.UTC.apply(this, data[i].date);

            // Do we need to remove the first point in the chart?
            if ((config.chart.series[0].activePointCount > 0) && (date - config.chart.series[0].xData[0] >= config.clean_interval*1000))
                config.chart.series[0].addPoint([date, data[i].result], false, true);
            else
                config.chart.series[0].addPoint([date, data[i].result], false);
        }

        // If there is data received, save the lastest id.
        if (data.length > 0)
            config.last_id = data[data.length-1].id;

        // Redraw the chart
        config.chart.redraw();
        
        setTimeout(function(){
            chartLive(config);
        }, config.interval*1000);
    });

}