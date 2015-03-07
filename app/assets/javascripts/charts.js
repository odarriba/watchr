var chart = null;
var chart_config = {};
var chart_last_id = "";

function chartStart(config) {
	chart_config = config || {};

	// Check if the container is defined
	if (chart_config == {})
		return;

	$('#'+chart_config.container).highcharts({
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
                text: chart_config.resume
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

    chart = $('#'+chart_config.container).highcharts();
}

function chartLive(url, interval) {
    url = url || window.location+"/data.json";
    interval = interval || 2000;

    if (chart_last_id != "") {
        var call_url = url + "?last=" + chart_last_id;
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
            if ((chart.series[0].activePointCount > 0) && (date - chart.series[0].xData[0] >= chart_config.clean_interval*1000))
                chart.series[0].addPoint([date, data[i].result], false, true);
            else
                chart.series[0].addPoint([date, data[i].result], false);
        }

        // If there is data received, save the lastest id.
        if (data.length > 0)
            chart_last_id = data[data.length-1].id;

        // Redraw the chart
        chart.redraw();
        
        setTimeout("chartLive('"+url+"',"+interval+")", chart_config.interval*1000);
    });

}