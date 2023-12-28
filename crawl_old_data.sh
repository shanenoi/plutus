#!/usr/bin/env bash

set -e

# Directory setup
script_directory=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
data_directory="$script_directory/data"
mkdir -p "$data_directory"

# Product map: Mapping of product keys to human-readable product names
declare -A product_map=(
  ["Nữ%20Trang%2041.7%"]="Nữ Trang 41.7%"
  ["Nữ%20Trang%2068%"]="Nữ Trang 68%"
  ["Nữ%20Trang%2099%"]="Nữ Trang 99%"
  ["Nữ%20Trang%2099.99%"]="Nữ Trang 99.99%"
  ["SJC%201L,%2010L,%201KG"]="SJC 1L, 10L, 1KG"
  ["SJC%202c%2C%201C%2C%205%20ph%C3%A2n"]="SJC 2c, 1C, 5 phân"
  ["SJC%205c"]="SJC 5c"
  ["V%C3%A0ng%20nh%E1%BA%ABn%20SJC%2099%2C99%200.3%20ch%E1%BB%89%2C%200.5%20ch%E1%BB%89"]="Vàng nhẫn SJC 99,99 0.3 chỉ, 0.5 chỉ"
  ["V%C3%A0ng%20nh%E1%BA%ABn%20SJC%2099%2C99%201%20ch%E1%BB%89%2C%202%20ch%E1%BB%89%2C%205%20ch%E1%BB%89"]="Vàng nhẫn SJC 99,99 1 chỉ, 2 chỉ, 5 chỉ"
)

# Function to download data for a specific product
download_data() {
  local product_key="$1"
  local product_name="$2"
  local file_name="$data_directory/$product_name.json"

  # Fetch data from tygia.io API
  if ! curl_output=$(curl -s "https://tygia.io/api/gold-prices/charts/sjc?duration=THREE_YEAR&productName=$product_key" \
    -H 'authority: tygia.io' \
    -H 'accept: application/json, text/plain, */*' \
    -H 'accept-language: en-US,en;q=0.9' \
    --compressed); then
    echo "[-] Failed to fetch data for $product_name"
    return 1
  fi

  # Decrypt the fetched data
  if ! decrypted_output=$(echo "$curl_output" | sed 's/"//g' | node -e "
    var CryptoJS = require('crypto-js');
    const input = require('fs').readFileSync(0, 'utf-8').trim()
    console.log(CryptoJS.DES.decrypt(input, 'TYGIA').toString(CryptoJS.enc.Utf8)); "); then
    echo "[-] Failed to decrypt data for $product_name"
    return 1
  fi

  # Write decrypted data to a file
  if ! echo "$decrypted_output" | jq > "$file_name"; then
    echo "[-] Failed to write data to $file_name for $product_name"
    return 1
  fi

  echo "[+] Completed downloading data for $product_name"
}

# Iterate over each product in the product_map and download the data
for product_key in "${!product_map[@]}"; do
  product_name="${product_map[$product_key]}"
  if ! download_data "$product_key" "$product_name"; then
    continue
  fi
done

# Check if data was downloaded successfully
if [ "$(ls -A "$data_directory")" ]; then
  echo "[+] Downloaded data to $data_directory"
  echo "[+] Transforming to SQL..."
  # Transform the downloaded data to SQL
  if python3 "$script_directory/transform.py" "$data_directory" > "$data_directory/final.sql"; then
    echo "[+] Conversion to SQL completed"
  else
    echo "[-] Failed to transform data to SQL"
  fi
else
  echo "[-] No data downloaded"
fi
