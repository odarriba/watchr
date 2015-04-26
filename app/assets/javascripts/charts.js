var chart = null;
var chart_config = {};
var chart_last_id = "";

function chartStart(config) {
	config = config || {};

    config.live = config.live || true;

	// Check if the container is defined
	if (config == {})
		return;

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
                },
                fillColor: {
                    linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1},
                    stops: [
                        [0, Highcharts.getOptions().colors[0]],
                        [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
                    ]
                }
            }
        },

        series: [{
            name: config.texts.legend,
            data: [
            ]
        }]
    });

    config.chart = $(config.container).highcharts();

    if (config.live)
        chartLive(config);
}

function chartLive(config) {
    url = config.data_url || window.location+"/data.json";

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