#!/usr/bin/env bash

echo -e "\nStarting script at $(date)..."

# Get the script directory and source the .env file
script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$script_dir/.env"

# Create the directory for storing gold price files
gold_price_dir="/tmp/gold_price"
mkdir -p "$gold_price_dir"

# Define the filename with the current date and time
filename="$gold_price_dir/$(date +"%Y.%m.%d_%H.%M").html"

# Download the gold price content
curl -s 'https://sjc.com.vn/giavang/textContent.php' \
  -H 'authority: sjc.com.vn' \
  -H 'accept-language: en-US,en;q=0.9' \
  --compressed > "$filename"

# Read the file contents into a variable
file_contents=$(cat "$filename")

# Extract the unit from the file contents
unit=$(grep -o 'Đơn vị tính:[^<>]*' <<< "$file_contents" | sed 's/^[^:]*: //g')

# Extract and format the updated_at timestamp using Python
time_str=$(grep -o '[0-9]*:[0-9]*:[0-9]* [APM]* [^<]*' <<< "$file_contents")
updated_at=$(python3 -c '
from datetime import datetime, timezone, timedelta
import sys

time_str = sys.stdin.read().strip()
time_obj = datetime.strptime(time_str, "%I:%M:%S %p %d/%m/%Y")
tz_offset = 7 # UTC+7
tz_obj = timezone(timedelta(hours=tz_offset))
time_obj_tz = time_obj.replace(tzinfo=tz_obj)

print(time_obj_tz.isoformat())
' <<< "$time_str")


# Insert the raw content into the database
echo -n "[+] Insert raw content - "
/opt/homebrew/opt/libpq/bin/psql "$POSTGRES_DSN" -v updated_at="$updated_at" -v content="$file_contents" <<SQL
  INSERT INTO plutus.raw_contents
  VALUES (:'updated_at', :'content')
  ON CONFLICT DO NOTHING
SQL

index=0
while IFS= read -r line; do
  fixed_line=$(echo "$line" | sed 's/<br[^>]*>//g')
  price_name=$(grep -o 'td class="br bb ylo2_text p12"[^<]*' <<< "$fixed_line" | sed 's/^[^>]*>//g')

  # Check if the price_name is not empty
  if [[ -n "$price_name" ]]; then
    # shellcheck disable=SC2094
    buy=$(awk -v i=$((index+2)) 'NR == i {gsub(/<[^<>]*>/, ""); gsub(/[, ]/, ""); print}' "$filename")
    # shellcheck disable=SC2094
    sell=$(awk -v i=$((index+3)) 'NR == i {gsub(/<[^<>]*>/, ""); gsub(/[, ]/, ""); print}' "$filename")

    # Insert the price into the database
    echo -n "[+] Update price: $price_name - $updated_at - "
    /opt/homebrew/opt/libpq/bin/psql "$POSTGRES_DSN" -v data_source_id="sjc.com.vn" -v name="$(echo "$price_name" | xargs)" -v updated_at="$updated_at" -v buy="$buy" -v sell="$sell" -v unit="$unit" <<SQL
      INSERT INTO plutus.prices
        (data_source_id, name, updated_at, buy, sell, unit)
      VALUES
        (:'data_source_id', :'name', :'updated_at', :buy, :sell, :'unit')
      ON CONFLICT DO NOTHING
SQL
  fi

  ((index++))
done < "$filename"
