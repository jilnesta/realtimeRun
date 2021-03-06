﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="map.aspx.cs" Inherits="RealtimeRun.index" %>

<!DOCTYPE html>
<html>
<head>
    <title>Realtime Run</title>

    <!-- avoids IE compatibility mode on intranets (useful for testing) -->
    <meta http-equiv="X-UA-Compatible" content="IE=Edge" />

    <link rel="Stylesheet" type="text/css" href="css/styles.css" media="all" />

</head>
<body>
    <input id="btnTest" type="button" value="Test" />
    <div id="divOutput">0, 0</div>
    
    <div class="map" id="mapDiv"></div>


    <!--Script references. -->
    <!--Reference the jQuery library. -->
    <script src="Scripts/jquery-2.1.1.min.js"></script>
    <!--Reference the SignalR library. -->
    <script src="Scripts/jquery.signalR-2.1.2.min.js"></script>
    <!--Reference the autogenerated SignalR hub script. -->
    <script src="signalr/hubs"></script>

    <script type="text/javascript" src="http://ecn.dev.virtualearth.net/mapcontrol/mapcontrol.ashx?v=7.0"></script>

    <script type="text/javascript">

        var bingMapsKey = '<%= ConfigurationManager.AppSettings["BingMapsKey"] %>';

        var map = null;

        // start with center of contiguous U.S.
        var initialLat = 39.83333;
        var initialLon = -98.58333;

        function getMap() {
            map = new Microsoft.Maps.Map(document.getElementById("mapDiv"), {
                credentials: bingMapsKey,
                center: new Microsoft.Maps.Location(initialLat, initialLon),
                zoom: 5
            });
        }

        var coordCounter = 0;

        function formatNumber(x) {
            return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        }


        $(function () {

            var mh = $.connection.mapHub;

            // SignalR client method that will be sent data via MapHub.cs
            mh.client.broadcastLatLon = function (lat, lon, altitude, speed) {

                $("#divOutput").text(lat + ", " + lon + " altitude: " + altitude + ", speed: " + speed);

                try {

                    var pushpinOptions = { width: null, height: null, htmlContent: "<div class='pushPin'></div>" };
                    var pushpin = new Microsoft.Maps.Pushpin(new Microsoft.Maps.Location(lat, lon), pushpinOptions);
                    map.entities.push(pushpin);


                    map.setView({ zoom: map.getZoom(), center: new Microsoft.Maps.Location(lat, lon) });

                    var roundedAltitudeInFeet = Math.round(altitude * 3.281);

                    var speedInMph = Math.round(speed * 2.237);

                    // We're only going to add an infobox ~ every 300 meters (assuming data's coming from the phone)
                    if (coordCounter % 30 === 0) {

                        var kustomKontent = "<div class='infoBox'><div class='infoBoxContent'>";
                        kustomKontent += formatNumber(roundedAltitudeInFeet) + " ft, " + speedInMph;
                        kustomKontent += " mph" + "</div><div class='triangle'></div></div>";

                        var infoboxOptions = { showCloseButton: false, zIndex: 0, showPointer: true, htmlContent: kustomKontent };
                        var defaultInfobox = new Microsoft.Maps.Infobox(new Microsoft.Maps.Location(lat, lon), infoboxOptions);

                        map.entities.push(defaultInfobox);
                    }

                    coordCounter++;

                } catch (e) {
                    alert(e);
                }
            };


            function randomIntFromInterval(min, max) {
                return Math.floor(Math.random() * (max - min + 1) + min);
            }


            $.connection.hub.start().done(function () {

                // Test function to see if SignalR is working
                $("#btnTest").click(function () {

                    var splitLat = initialLat.toString().split(".");
                    var splitLon = initialLon.toString().split(".");

                    // This just generates a random lat/lon within a few kilometers distance
                    var newLat = splitLat[0] + "." + splitLat[1].substr(0,1) + randomIntFromInterval(4, 6) + randomIntFromInterval(0, 99);
                    var newLon = splitLon[0] + "." + splitLon[1].substr(0, 1) + randomIntFromInterval(4, 6) + randomIntFromInterval(0, 99);

                    try {

                        // Calls the Send method in MapHub.cs
                        mh.server.send(newLat, newLon, 0, 0);

                        console.log("Sent test data to server");
                    } catch (e) {

                        console.error("send error: " + e);
                    }
                });
            });
        });


        // Optional code to set the initial location to wherever you are
        function getPosition(position) {
            console.log("Latitude: " + position.coords.latitude +
            " Longitude: " + position.coords.longitude);

            initialLat = position.coords.latitude;
            initialLon = position.coords.longitude;

            map.setView({ zoom: 12, center: new Microsoft.Maps.Location(initialLat, initialLon) });
        }

        function processLocationError(error) {
            console.error(error, error.message);
        }

        function getLocation() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(getPosition, processLocationError);
            } else {
                console.error("Geolocation is not supported by this browser.");
            }
        }

        getLocation();

        getMap();

    </script>
</body>
</html>
