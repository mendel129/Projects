// fetch aranet 4 sensor values data over BLE and send over MQTT to HASS
// a little bit of vibe coding and https://github.com/Anrijs/Aranet4-ESP32/blob/main/examples/BasicRead/BasicRead.ino for https://www.az-delivery.de/en/products/esp32-developmentboard

#include <WiFi.h>
#include <WebServer.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "Aranet4.h"

// ====== CONFIGURATION ======
// Wi-Fi
const char* ssid = "mywifi";
const char* password = "mywifipassword";

// MQTT broker (Home Assistant)
const char* mqtt_server = "192.168.1.1"; // replace with your broker IP or hostname
const int mqtt_port = 1883;
const char* mqtt_user = "user";       // set to nullptr or "" if no auth
const char* mqtt_password = "password";   // set to nullptr or "" if no auth

// MQTT topics & discovery
const char* discovery_prefix = "homeassistant";
const char* base_state_topic = "aranet4/sensors";
const char* device_id = "aranet4_01"; // unique per physical device

// Aranet4 BLE address
String addr = "cc:a8:0a:aa:aa:aa";

// ====== GLOBALS ======
WiFiClient espClient;
PubSubClient mqttClient(espClient);
WebServer server(80);
AranetData data;

unsigned long lastPublish = 0;
const unsigned long PUBLISH_INTERVAL_MS = 300UL * 1000UL; // 300 seconds

// HTML page template
String aranet4HTML = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Aranet4 Sensor Data</title>
  <meta http-equiv="refresh" content="10">
  <style>
    body { font-family: Arial; background: #f8f9fa; padding: 20px; }
    h2 { color: #343a40; }
    table { border-collapse: collapse; width: 400px; }
    th, td { border: 1px solid #dee2e6; padding: 8px; text-align: left; }
    th { background-color: #e9ecef; }
  </style>
</head>
<body>
  <h2>Aranet4 Sensor Readout</h2>
  <table>
    <tr><th>Parameter</th><th>Value</th></tr>
    <tr><td>CO₂</td><td>%CO2% ppm</td></tr>
    <tr><td>Temperature</td><td>%TEMP% °C</td></tr>
    <tr><td>Pressure</td><td>%PRES% hPa</td></tr>
    <tr><td>Humidity</td><td>%HUMID% %</td></tr>
    <tr><td>Battery</td><td>%BATTERY% %</td></tr>
    <tr><td>Interval</td><td>%INTERVAL% s</td></tr>
    <tr><td>Last Seen</td><td>%AGO% s ago</td></tr>
  </table>
</body>
</html>
)rawliteral";

// ====== Aranet4 callback stub (if PIN needed) ======
class MyAranet4Callbacks: public Aranet4Callbacks {
    uint32_t onPinRequested() {
        Serial.println("PIN Requested. Enter PIN in serial console.");
        while (Serial.available() == 0)
            vTaskDelay(500 / portTICK_PERIOD_MS);
        return Serial.readString().toInt();
    }
};

Aranet4 ar4(new MyAranet4Callbacks());

// ====== FUNCTIONS ======
void setup_wifi() {
  delay(10);
  Serial.printf("Connecting to Wi-Fi '%s' ...", ssid);
  WiFi.begin(ssid, password);
  int tries = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    if (++tries > 60) { // after ~30s restart attempt
      Serial.println("\nWi-Fi connect failed, restarting...");
      ESP.restart();
    }
  }
  Serial.println("\nWiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void handleRoot() {
  String htmlPage = aranet4HTML;
  htmlPage.replace("%CO2%", String(data.co2));
  htmlPage.replace("%TEMP%", String(data.temperature / 20.0, 2));
  htmlPage.replace("%PRES%", String(data.pressure / 10.0, 1));
  htmlPage.replace("%HUMID%", String(data.humidity));
  htmlPage.replace("%BATTERY%", String(data.battery));
  htmlPage.replace("%INTERVAL%", String(PUBLISH_INTERVAL_MS / 1000));
  htmlPage.replace("%AGO%", String(data.ago));
  
  server.send(200, "text/html", htmlPage);
}

void setup_http_server() {
  server.on("/", handleRoot);
  server.begin();
  Serial.println("HTTP server started");
}

// ----- MQTT / Home Assistant discovery -----
void publish_ha_discovery() {
  // Temperature sensor
  {
    StaticJsonDocument<512> tempCfg;
    tempCfg["name"] = "Aranet4 Temperature";
    tempCfg["state_topic"] = base_state_topic;
    tempCfg["value_template"] = "{{ value_json.temperature }}";
    tempCfg["unit_of_measurement"] = "°C";
    tempCfg["unique_id"] = "aranet4_temperature";
    //JsonObject device = tempCfg.createNestedObject("device");
   // device["identifiers"] = JsonArray().add(device_id);
    //device["name"] = "Aranet4";
    //device["model"] = "Aranet4";
    //device["manufacturer"] = "Senseair";

    char buf[512];
    size_t len = serializeJson(tempCfg, buf);
    String topic = String(discovery_prefix) + "/sensor/aranet4_temperature/config";
    mqttClient.publish(topic.c_str(), buf, true);

    Serial.println("publish_ha_discovery Aranet4 Temperature on " + topic);
  }

  // Humidity sensor
  {
    StaticJsonDocument<512> humCfg;
    humCfg["name"] = "Aranet4 Humidity";
    humCfg["state_topic"] = base_state_topic;
    humCfg["value_template"] = "{{ value_json.humidity }}";
    humCfg["unit_of_measurement"] = "%";
    humCfg["unique_id"] = "aranet4_humidity";
    //JsonObject device2 = humCfg.createNestedObject("device");
    //device2["identifiers"] = JsonArray().add(device_id);
    //device2["name"] = "Aranet4";
    //device2["model"] = "Aranet4";
    //device2["manufacturer"] = "Senseair";

    char buf[512];
    size_t len = serializeJson(humCfg, buf);
    String topic = String(discovery_prefix) + "/sensor/aranet4_humidity/config";
    mqttClient.publish(topic.c_str(), buf, true);
  }

  // CO2 sensor
  {
    StaticJsonDocument<512> co2Cfg;
    co2Cfg["name"] = "Aranet4 CO2";
    co2Cfg["state_topic"] = base_state_topic;
    co2Cfg["value_template"] = "{{ value_json.co2 }}";
    co2Cfg["unit_of_measurement"] = "ppm";
    co2Cfg["unique_id"] = "aranet4_co2";
    //JsonObject device3 = co2Cfg.createNestedObject("device");
    //device3["identifiers"] = JsonArray().add(device_id);
    //device3["name"] = "Aranet4";
    //device3["model"] = "Aranet4";
    //device3["manufacturer"] = "Senseair";

    char buf[512];
    size_t len = serializeJson(co2Cfg, buf);
    String topic = String(discovery_prefix) + "/sensor/aranet4_co2/config";
    mqttClient.publish(topic.c_str(), buf, true);
  }
}

void ensureMqttConnected() {
  if (mqttClient.connected()) return;

  Serial.print("Connecting to MQTT...");
  String clientId = "ESP32_Aranet4_";
  clientId += String(random(0xffff), HEX);

  bool connected;
  if (mqtt_user && strlen(mqtt_user) > 0) {
    connected = mqttClient.connect(clientId.c_str(), mqtt_user, mqtt_password);
  } else {
    connected = mqttClient.connect(clientId.c_str());
  }

  if (connected) {
    Serial.println(" connected");
    publish_ha_discovery();
  } else {
    Serial.print(" failed, rc=");
    Serial.println(mqttClient.state());
    // backoff is internal to PubSubClient; loop will retry on next iteration
  }
}

void setup_mqtt() {
  mqttClient.setServer(mqtt_server, mqtt_port);
}

void publish_sensor_data(float temperature, float humidity, int co2_ppm) {
  StaticJsonDocument<256> root;
  root["temperature"] = temperature;
  root["humidity"] = humidity;
  root["co2"] = co2_ppm;

  char payload[256];
  serializeJson(root, payload);
  bool ok = mqttClient.publish(base_state_topic, payload);
  if (ok) {
    Serial.printf("Published to MQTT: %s\n", payload);
  } else {
    Serial.println("Failed to publish sensor data");
  }
}

// ====== SETUP & LOOP ======
void setup() {
  Serial.begin(115200);
  delay(100);

  setup_wifi();
  setup_http_server();
  setup_mqtt();

  Aranet4::init();

  // seed random for client ID
  randomSeed(esp_random());
}

void loop() {
  server.handleClient();

  // ensure connectivity
  if (WiFi.status() != WL_CONNECTED) {
    setup_wifi(); // try reconnecting
  }

  ensureMqttConnected();
  mqttClient.loop();

  unsigned long now = millis();
  if (now - lastPublish >= PUBLISH_INTERVAL_MS) {
    lastPublish = now;

    // BLE read (blocking as before)
    ar4.connect(addr);
    data = ar4.getCurrentReadings();
    ar4.disconnect();

    float temperature = data.temperature / 20.0; // scale per your original
    float humidity = data.humidity;
    int co2 = data.co2;

    publish_sensor_data(temperature, humidity, co2);
  }
}
