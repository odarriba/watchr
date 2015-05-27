/*
 * Function to start the representation of an auto-updated chart using
 * a configuration hash obtained by the parameter 'chart_config':
 *
 * {
 *    container: containerObject,
 *    live: true|false,
 *    interval: updateIntervalInMiliseconds,
 *    clean_interval: cleanIntervalInMiliseconds,
 *    texts: {
 *      title: "Title of the chart",
 *      subtitle: "Subtitle of the chart",
 *      x_axis: "X axis text",
 *      y_axis: "Y axis text",
 *      legend: "Legend of the data"
 *    },
 *    data_url: "URL to obtain the data using GET method",
 *    resume: "resume function passed to the URL by 'resume' parameter."
 *  }
 */
function chartStart(config) {
	config = config || {};

	// Check if the container is defined
	if (config == {})
		return;

    config.live = config.live || true;
    config.resume = config.resume || "default";
    config.last_id = config.last_id || "";

	$(config.container).highcharts({
        chart: {
            type: 'areaspline',
            height: config.height,
            zoomType: 'x'
        },
        title: {
            text: config.texts.title
        },
        subtitle: {
            text: config.texts.subtitle
        },
        xAxis: {
            type: 'datetime',
            dateTimeLabelFormats: { // don't display the dummy year
                month: '%e. %b',
                year: '%b'
            },
            title: {
                text: config.texts.x_axis
            }
        },
        yAxis: {
            title: {
                text: config.texts.y_axis
            },
            min: 0
        },
        tooltip: {
            headerFormat: '<b>{point.y:.4f}</b><br>',
            pointFormat: '{point.x:%H:%M:%S - %d/%m/%Y}'
        },

        plotOptions: {
            areaspline: {
                marker: {
                    enabled: false
                }
            }
        },

        series: [{
            name: config.texts.legend,
            data: [
            ]
        }]
    });

    // Get the chart object
    config.chart = $(config.container).highcharts();

    // Update the chart
    chartUpdate(config);

    if (config.live == true)
        return setInterval(function(){
            chartUpdate(config);
        }, config.interval*1000);

    return true;
}

/*
 * Function to stop the auto-update of a chart by removing it's config.
 */
function chartStop(chart_id) {
    // Drop the config
    clearInterval(chart_id);
}

/*
 * Function to update the chart data according to it's config, going an AJAX call.
 */
function chartUpdate(config) {
    // Is it valid?
    if (config == null)
        return;

    // Generate the URL
    var base_url = config.data_url || window.location+"/data.json";
    var call_url = base_url + "?resume="+config.resume
    if (config.last_id != "") {
        call_url = call_url + "&last=" + config.last_id;
    }

    // Do the API call
    $.getJSON(call_url).success(function(data){
        for (var i = 0; i < data.length; i++) {
            //data[i].date[2]--; // Correct month number

            // Create date object
            //var date = Date.UTC.apply(this, data[i].date);
            //var date = new Date(data[i].date*1000).toISOString();

            // Do we need to remove the first point in the chart?
            if ((config.chart.series[0].activePointCount > 0) && (date - config.chart.series[0].xData[0] >= config.clean_interval*1000))
                config.chart.series[0].addPoint([data[i].date*1000, data[i].result], false, true);
            else
                config.chart.series[0].addPoint([data[i].date*1000, data[i].result], false);
        }

        // If there is data received, save the lastest id.
        if (data.length > 0)
            config.last_id = data[data.length-1].id;

        // Redraw the chart
        config.chart.redraw();
    });

}