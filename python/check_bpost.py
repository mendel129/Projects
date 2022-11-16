import requests, json

barcode=input("barcode: ")
postcode=input("postcode: ")

resp=requests.get("https://track.bpost.cloud/track/items?itemIdentifier="+barcode+"&postalCode="+postcode)
# print(json.dumps(resp.json(), indent=3))
jsondata=resp.json()
print(jsondata["items"][0]["activeStep"]["label"]["main"]["EN"])

for event in jsondata["items"][0]["events"]:
    print("---- " + str(event["date"]) + " - " + str(event["time"]) + " - " + str(event["key"]["EN"]["description"]))

resp=requests.get("https://track.bpost.cloud/track/itemonroundstatus?itemIdentifier="+barcode+"&postalCode="+postcode)
print("Stops to do: " + resp.json()["itemOnRoundStatus"]["nrOfStopsUntilTarget"][0])
