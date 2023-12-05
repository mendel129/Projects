# for the awesome https://github.com/Blueforcer/awtrix-light
import requests,json

ip="192.168.1.169"
url="http://"+ip+"/api"

# print((requests.get(url+"/effects")).text)
# print((requests.get(url+"/settings")).text)
# print((requests.get(url+"/stats")).text)

# BRI Matrix brightness.
# ABRI Automatic brightness control.
# print((requests.get(url+"/settings")).json()["BRI"])
# print((requests.get(url+"/settings")).json()["ABRI"])
# print(requests.post(url+"/settings", json={"ABRI": "true"}))
# # print(requests.post(url+"/settings", json={"ABRI": False}))
# # print(requests.post(url+"/settings", json={"BRI": "200"}))
# print((requests.get(url+"/settings")).json()["BRI"])
# print((requests.get(url+"/settings")).json()["ABRI"])

# get available apps 
# print((requests.get(url+"/loop")).text)
# print(requests.post(url+"/custom?name=testapp", json={"text": "hello test", "rainbow": True, "duration": "10"}))
requests.post(url+"/custom?name=testapp", json={"effect": "Matrix", "duration": "10"})
# use to delete
# print(requests.post(url+"/custom?name=testapp", json={}))

#https://github.com/TimFranken/openkmi
import requests, json, datetime
wfs_endpoint = "https://opendata.meteo.be/service/synop/wfs?outputFormat=json"
wfs_request_xml = f"""
<wfs:GetFeature xmlns:wfs="http://www.opengis.net/wfs"
                xmlns:ogc="http://www.opengis.net/ogc"
                xmlns:gml="http://www.opengis.net/gml/3.2"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengis.net/wfs/2.0/wfs.xsd">
    <wfs:Query typeName="synop:synop_data">
        <wfs:PropertyName>temp</wfs:PropertyName>
        <wfs:PropertyName>timestamp</wfs:PropertyName>
        <wfs:Filter>
            <ogc:And xmlns:ogc="http://www.opengis.net/ogc"><ogc:PropertyIsEqualTo><ogc:PropertyName>code</ogc:PropertyName><ogc:Literal>6438</ogc:Literal></ogc:PropertyIsEqualTo><ogc:PropertyIsGreaterThanOrEqualTo><ogc:PropertyName>timestamp</ogc:PropertyName><ogc:Literal>{(datetime.datetime.now()-datetime.timedelta(hours=3)).strftime("%Y-%m-%dT%H:00:00")}</ogc:Literal></ogc:PropertyIsGreaterThanOrEqualTo></ogc:And>
        </wfs:Filter>
    </wfs:Query>
</wfs:GetFeature>
"""
headers = {"Content-Type": "application/xml"}
response = requests.post(wfs_endpoint, data=wfs_request_xml, headers=headers)
for data in response.json()["features"]:
    temp_value=data["properties"]["temp"]
    # print(data["properties"]["temp"])
    # print(data["properties"]["timestamp"])
requests.post(url+"/custom?name=testapp", json={"text":str(temp_value), "effect": "Matrix", "duration": "10"})
requests.post(url+"/switch", json={"name":"testapp"})
