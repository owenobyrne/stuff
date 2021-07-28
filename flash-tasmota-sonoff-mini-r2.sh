#!/bin/bash

echo "Flash Tasmota to Sonoff Mini R2"
echo ""

# Check if we have jq
if ! command -v jq &> /dev/null
then
    echo "'jq' could not be found, but is needed - please install using 'brew install jq'"
    exit
fi

echo "This a multi-step process: "
echo " 1. Hold down the button for 5 seconds to enter DIY mode."
echo " 2. Connect to Sonoff Wifi (ITEAD-xxxx) via mobile - password is 12345678."
echo " 3. Browse to 10.10.7.1 on mobile - setup connection to home wifi."
echo " 4. Use an app such as Fing to find the DHCP-assigned IP on home wifi. (possibly as an Espressif device)"

echo ""
echo -n "Enter IP address: "
read IP_ADDRESS

INFO=$(curl --silent --request POST "http://$IP_ADDRESS:8081/zeroconf/info" --header 'Content-Type: application/json' --data-raw '{"deviceid":"","data":{ } }')
ERROR=$(echo $INFO | jq .error)
OTA_UNLOCK=$(echo $INFO | jq .data.otaUnlock)

if [ ! $ERROR -eq 0 ]
then 
    echo "Error contacting the device: $INFO"
    exit
fi

echo ""

if [ $OTA_UNLOCK = "true" ] 
then 
    echo "Device is already unlocked, skipping unlock step."
else
    echo -n "Unlocking device..."
    UNLOCK=$(curl --silent --request POST "http://$IP_ADDRESS:8081/zeroconf/ota_unlock" --header 'Content-Type: application/json' --data-raw '{"deviceid":"","data":{ } }')
    
    ERROR=$(echo $UNLOCK | jq .error)
    if [ ! $ERROR -eq 0 ]
    then 
        echo "Error unlocking the device: $UNLOCK"
        exit
    else 
        echo "OK!"
    fi
    
    echo $UNLOCK

    INFO=$(curl --silent --request POST "http://$IP_ADDRESS:8081/zeroconf/info" --header 'Content-Type: application/json' --data-raw '{"deviceid":"","data":{ } }')
    echo $INFO

    OTA_UNLOCK=$(echo $INFO | jq .data.otaUnlock)
    if [ ! $OTA_UNLOCK = "true" ] 
    then 
        echo "Device not unlocked! $INFO"
        exit
    fi
fi

echo ""
echo -n "Flashing Tasmota 9.2.0-lite (can't do full here - upgrade afterwards)... "
FLASH=$(curl --silent --request POST "http://$IP_ADDRESS:8081/zeroconf/ota_flash" --header 'Content-Type: application/json' --data-raw '{"deviceid":"","data":{"downloadUrl": "http://sonoff-ota.aelius.com/tasmota-9.2.0-lite.bin", "sha256sum": "c61dd7448ce5023ca5ca8997833fd240829c902fa846bafca281f01c0c5b4d29"} }')

ERROR=$(echo $FLASH | jq .error)
if [ ! $ERROR -eq 0 ]
then 
    echo "Error unlocking the device: $FLASH"
    exit
else 
    echo "OK!"
fi

echo $FLASH

echo "Wait for new 'tasmota_xxx' wifi to appear. Connect on mobile and connect to home wifi."
echo "Continue to set up and upgrade to tasmota-9.2.0-minimal, then full."
echo "Use the following template to set up the Mini: "
echo "{\"NAME\":\"Sonoff Mini\",\"GPIO\":[17,0,0,0,9,0,0,0,21,56,0,0,255],\"FLAG\":0,\"BASE\":1}"
echo ""
echo "Connect to MQTT"

