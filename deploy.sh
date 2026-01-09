#!/bin/bash

# Caminho para a pasta do MT5 (ajuste o ID do terminal)

MT5_PATH="/mnt/c/MT5/MQL5/Indicators/SyncObjects"

mkdir -p "$MT5_PATH"

cp SyncObjects.mq5 "$MT5_PATH/"

cp Context7_Logic.mqh "$MT5_PATH/"

echo "Deploy concluído para o MT5!"