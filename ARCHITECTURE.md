
LiVE Relay Architecture
=======================

Input
-----

LiVE Relay Server: `live.example.com`<br/>
LiVE Access Token: `example-XXXX-YYYY`

Result
------

- Video Stream:<br/>
  URL: `rtmps://live.example.com/stream/example?key=XXXX-YYYY`<br/>
  Protocol: RTMP/TLS/TCP/IP

- Event Stream:<br/>
  URL: `mqtts://XXXX:YYYY@live.example.com/stream/example`<br/>
  Protocol: MQTT/TLS/TCP/IP

