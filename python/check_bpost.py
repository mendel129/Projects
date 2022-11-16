import requests, json

barcode=input("barcode: ")
postcode=input("postcode: ")
arrived=True

def checkpacket(barcode, postcode):
    try:
        resp=requests.get("https://track.bpost.cloud/track/items?itemIdentifier="+barcode+"&postalCode="+postcode)
        # print(json.dumps(resp.json(), indent=3))
        jsondata=resp.json()
        print(jsondata["items"][0]["activeStep"]["label"]["main"]["EN"])
        print(jsondata["items"][0]["expectedDeliveryTimeRange"]["day"] + " between " +  jsondata["items"][0]["expectedDeliveryTimeRange"]["time1"] + " and " + jsondata["items"][0]["expectedDeliveryTimeRange"]["time2"])

        for event in jsondata["items"][0]["events"]:
            print("---- " + str(event["date"]) + " - " + str(event["time"]) + " - " + str(event["key"]["EN"]["description"]))

        if jsondata["items"][0]["activeStep"]["name"] == "out_for_delivery":
            resp=requests.get("https://track.bpost.cloud/track/itemonroundstatus?itemIdentifier="+barcode+"&postalCode="+postcode)
            print("Stops to do: " + resp.json()["itemOnRoundStatus"]["nrOfStopsUntilTarget"][0])
            
        if jsondata["items"][0]["activeStep"]["name"] == "delivered":
            return 0
        else:
            return 1
    except BaseException as e:
        print(e)
        return 1
    
    
while(arrived):
    arrived=checkpacket(barcode, postcode)
    if arrived:
        time.sleep(30)
