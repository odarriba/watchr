/*
 * Function to start the representation of an auto-updated chart using
 * a configuration hash obtained by the parameter 'chart_config':
 *
 * {
 *    container: containerObject,
 *    live: true|false,
 *    zoomable: true|false
 *    interval: updateIntervalInMiliseconds,
 *    points_limit: limitOfPointsToShow,
 *    texts: {
 *      title: "Title of the chart",
 *      subtitle: "Subtitle of the chart",
 *      x_axis: "X axis text",
 *      y_axis: "Y axis text",
 *      legend: "Legend of the data",
 *      loading: "Loading text"
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

    var chart_config = {
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
            headerFormat: '',
            pointFormat: '<b>{point.y:.4f}</b><br>{point.x:%H:%M:%S - %d/%m/%Y}'
        },
        rangeSelector: {
            enabled: true,
            inputEnabled: false,
            buttons: [{
                type: 'hour',
                count: 1,
                text: '1h'
            }, {
                type: 'day',
                count: 1,
                text: '1d'
            }, {
                type: 'day',
                count: 2,
                text: '2d'
            }, {
                type: 'month',
                count: 1,
                text: '1m'
            }, {
                type: 'year',
                count: 1,
                text: '1y'
            }, {
                type: 'all',
                text: 'All'
            }],
            selected: 0
        },
        navigator: {
            enabled: true
        },
        scrollbar : {
            enabled : false
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
    };

    if (config.zoomable == false) {
        chart_config.rangeSelector.enabled = false;
        chart_config.navigator.enabled = false;
    }

	$(config.container).highcharts("StockChart", chart_config);

    config.config = chart_config;

    // Get the chart object
    config.chart = $(config.container).highcharts();

    config.chart.showLoading(config.texts.loading);

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
    var base_url = config.data_url || window.location + "/data.json";
    var call_url = base_url + "?resume=" + config.resume
    if (config.last_id != "") {
        call_url = call_url + "&last=" + config.last_id;
    }
    if (config.points_limit != undefined) {
        call_url += "&limit=" + config.points_limit
    }

    // Do the API call
    $.getJSON(call_url).success(function(data){
        if (config.chart.series[0].data.length == 0) {
            var chartData = [];

            for (var i = data.length-1; i >= 0; i--)
                chartData.push([data[i].date*1000, data[i].result]);

            var chart = $(config.container).highcharts();
            chart.series[0].setData(chartData);
        }
        else {
            for (var i = 0; i < data.length-1; i++) {
                // Do we need to remove the first point in the chart?
                if ((config.points_limit != undefined) && (config.chart.series[0].data.count > config.points_limit))
                    config.chart.series[0].addPoint([data[i].date*1000, data[i].result], false, true);
                else
                    config.chart.series[0].addPoint([data[i].date*1000, data[i].result], false);
            }
        }

        // If there is data received, save the lastest id.
        if (data.length > 0)
            config.last_id = data[0].id;

        // 10 msec later, print the latest point.
        // This code is to solve a bug with the rangeSelector of HighStock
        setTimeout(function() {
            if (data.length > 0)
                config.chart.series[0].addPoint([data[data.length-1].date*1000, data[data.length-1].result], false);

            config.chart.redraw();
            config.chart.hideLoading();
        }, 10);
    });

    // Redraw the chart
    config.chart.redraw();
}