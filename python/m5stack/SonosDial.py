# mendelonline.be
# http://docs.m5stack.com/en/core/M5Dial
# https://uiflow2.m5stack.com/
# 2025/02/14
# some pretty basic hardcoded script to control 2 sonos speakers

import os, sys, io, re
import M5
from M5 import *
from hardware import *
import requests2

lbl_speaker = None
lbl_track = None
label0 = None
rotary = None
#static ip's of sonos masters
sonos_ip_office = "192.168.1.62"
sonos_ip_living = "192.168.1.149"
#default to office
sonos_ip=sonos_ip_office
speaker = None
image0 = None
image1 = None
image2 = None
image3 = None
slowdown = 0
lbl_trackx=0
slowdownlabelx=0
trackid = ""



#mute on button click
def btnA_wasClicked_event(state):
  global label0, rotary, lbl_speaker
  rotary.reset_rotary_value()
  label0.setText(str(rotary.get_rotary_value()))
  set_sonos_volume(sonos_ip, "0")
  #debug
  #lbl_speaker.setText("mute")


def get_sonos_volume(sonos_ip):
    url = f"http://{sonos_ip}:1400/MediaRenderer/RenderingControl/Control"
    headers = {
        "Content-Type": "text/xml; charset=utf-8",
        "SOAPACTION": '"urn:schemas-upnp-org:service:RenderingControl:1#GetVolume"',
    }

    body = f"""<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>
            <u:GetVolume xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1">
                <InstanceID>0</InstanceID>
                <Channel>Master</Channel>
            </u:GetVolume>
        </s:Body></s:Envelope>"""

    try:
        response = requests2.post(url, headers=headers, data=body)
        if response.status_code == 200:
            start_tag = "<CurrentVolume>"
            end_tag = "</CurrentVolume>"          
            xml_data=response.content.decode('utf-8')
            start_index = xml_data.find(start_tag) + len(start_tag)
            end_index = xml_data.find(end_tag)
            current_volume = xml_data[start_index:end_index]
            return current_volume
        else:
            print(f"Request failed with status code {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"Error: {e}")

def set_sonos_volume(sonos_ip, VOLUME):
    url = f"http://{sonos_ip}:1400/MediaRenderer/RenderingControl/Control"
    headers = {
        'Content-Type': 'text/xml; charset="utf-8"',
        'SOAPACTION': '"urn:schemas-upnp-org:service:RenderingControl:1#SetVolume"',
    }
       
    body = f"""<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
            <s:Body>
                <u:SetVolume xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1">
                    <InstanceID>0</InstanceID>
                    <Channel>Master</Channel>
                    <DesiredVolume>{VOLUME}</DesiredVolume>
                </u:SetVolume>
            </s:Body></s:Envelope>"""
        
    try:
        response = requests2.post(url, data=body, headers=headers)
    except Exception as e:
        print(f"Error: {e}")


def trackcontrol_sonos(sonos_ip, action):
    #debug
    #lbl_speaker.setText(str(action))
    url = f"http://{sonos_ip}:1400/MediaRenderer/AVTransport/Control"
    headers = {
        'Content-Type': 'text/xml; charset="utf-8"',
        'SOAPACTION': '"urn:schemas-upnp-org:service:AVTransport:1#'+action+'"',
    }

    if action=="Play":
      soapcontent="<InstanceID>0</InstanceID><Speed>1</Speed>"
    elif action in ["Next", "Pause", "Previous", "GetPositionInfo"]:
      soapcontent="<InstanceID>0</InstanceID>"
    else:
      soapcontent=""
       
    body = f"""<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
            <s:Body>
                <u:{action} xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                    {soapcontent}
                </u:{action}>
            </s:Body>
        </s:Envelope>"""
        
    try:
        if soapcontent is not "":
          response = requests2.post(url, data=body, headers=headers)
          if action=="GetPositionInfo":
            start_tag = "<TrackMetaData>"
            end_tag = "</TrackMetaData>"          
            xml_data=response.content.decode('utf-8')
            start_index = xml_data.find(start_tag) + len(start_tag)
            end_index = xml_data.find(end_tag)
            tracktitle = xml_data[start_index:end_index].split("dc:title&gt")[1][1:-5]
            tracktitle = tracktitle.replace("&amp;", "&")
            trackcreator = xml_data[start_index:end_index].split("dc:creator&gt")[1][1:-5]
            trackcreator = trackcreator.replace("&amp;", "&")
            trackid = trackcreator + " - " + tracktitle
            return trackid

    except Exception as e:
        print(f"Error: {e}")



def setup():
  global label0, rotary, sonos_ip, lbl_speaker, speaker, image0, image1, image2, image3, lbl_track, lbl_trackx, trackid
  M5.begin()
  Widgets.fillScreen(0xffffff)
  label0 = Widgets.Label("10", 80, 90, 1.0, 0x222222, 0xffffff, Widgets.FONTS.DejaVu56)
  lbl_speaker = Widgets.Label("office", 94, 30, 1.0, 0x222222, 0xffffff, Widgets.FONTS.DejaVu18)
  lbl_track = Widgets.Label("", 40, 55, 1.0, 0x222222, 0xffffff, Widgets.FONTS.DejaVu18)
  lbl_trackx=40
  image0 = Widgets.Image("res/img/pause.jpg", 130, 164, scale_x=0.5, scale_y=0.5)
  image1 = Widgets.Image("res/img/forward.jpg", 180, 90, scale_x=0.5, scale_y=0.5)
  image2 = Widgets.Image("res/img/rewind.jpg", 10, 90, scale_x=0.5, scale_y=0.5)
  image3 = Widgets.Image("res/img/play.jpg", 60, 164, scale_x=0.5, scale_y=0.5)
  speaker = 'office'
  BtnA.setCallback(type=BtnA.CB_TYPE.WAS_CLICKED, cb=btnA_wasClicked_event)
  currentvolume=get_sonos_volume(sonos_ip)
  rotary = Rotary(int(currentvolume))
  if int(currentvolume) > 9:
    label0.setCursor(80,90)
  else:
    label0.setCursor(100,90)
  label0.setText(str(currentvolume))
  trackid=str(trackcontrol_sonos(sonos_ip, "GetPositionInfo"))
  lbl_track.setText(trackid)


def loop():
  global label0, rotary, sonos_ip, lbl_speaker, sonos_ip_living, sonos_ip_office, speaker, lbl_track, slowdown, lbl_trackx, slowdownlabelx, trackid
  
  #only get current music every more or less 30 seconds? no clue on actual tick rate
  if slowdown > 1000000:
    trackid=trackcontrol_sonos(sonos_ip, "GetPositionInfo")
    lbl_track.setText(str(trackid))
    slowdown=0
  slowdown=slowdown+1

  if slowdownlabelx > 1000:
    trackidlength=len(trackid)*10
    #debug
    #lbl_speaker.setText(str(trackidlength))
    if lbl_trackx < ((1-trackidlength)-10):
      lbl_trackx=225
    lbl_trackx=lbl_trackx-1
    lbl_track.setCursor(lbl_trackx, 55)
    slowdownlabelx=0
  slowdownlabelx=slowdownlabelx+1
  
  M5.update()
  if rotary.get_rotary_status():
    rotaryvalue=rotary.get_rotary_value()
    if int(rotaryvalue) > 9:
      label0.setCursor(80,90)
    else:
      label0.setCursor(100,90)
    label0.setText(str(rotaryvalue))
    set_sonos_volume(sonos_ip, rotaryvalue)
  if (M5.Touch.getCount()) == 1:
    if 120 < (M5.Touch.getX()) and 220 > (M5.Touch.getX()):
      if 160 < (M5.Touch.getY()) and 220 > (M5.Touch.getY()):
          trackcontrol_sonos(sonos_ip, "Pause")
    elif 160 < (M5.Touch.getX()) and 250 > (M5.Touch.getX()):
      if 80 < (M5.Touch.getY()) and 150 > (M5.Touch.getY()):
          trackcontrol_sonos(sonos_ip, "Next")
          trackid=trackcontrol_sonos(sonos_ip, "GetPositionInfo")
          lbl_track.setText(str(trackid))  
    elif 0 < (M5.Touch.getX()) and 60 > (M5.Touch.getX()):
      if 80 < (M5.Touch.getY()) and 150 > (M5.Touch.getY()):
          trackcontrol_sonos(sonos_ip, "Previous")
          trackid=trackcontrol_sonos(sonos_ip, "GetPositionInfo")
          lbl_track.setText(str(trackid))
    elif 0 < (M5.Touch.getX()) and 100 > (M5.Touch.getX()):
      if 160 < (M5.Touch.getY()) and 220 > (M5.Touch.getY()):
          trackcontrol_sonos(sonos_ip, "Play")
    elif 10 < (M5.Touch.getX()) and 220 > (M5.Touch.getX()):
      if 0 < (M5.Touch.getY()) and 70 > (M5.Touch.getY()):
        if speaker == 'office':
          speaker = 'living'
          lbl_speaker.setText(str(speaker))
          sonos_ip=sonos_ip_living
          currentvolume=get_sonos_volume(sonos_ip)
          rotary = Rotary(int(currentvolume))
          label0.setText(str(currentvolume))
        else:
          speaker = 'office'
          lbl_speaker.setText(str(speaker))
          sonos_ip=sonos_ip_office
          currentvolume=get_sonos_volume(sonos_ip)
          rotary = Rotary(int(currentvolume))
          label0.setText(str(currentvolume))
    while (M5.Touch.getCount()) == 1:
      M5.update()


if __name__ == '__main__':
  try:
    setup()
    while True:
      loop()
  except (Exception, KeyboardInterrupt) as e:
    try:
      from utility import print_error_msg
      print_error_msg(e)
    except ImportError:
      print("please update to latest firmware")
