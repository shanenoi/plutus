import argparse
import json
from collections import defaultdict
from pathlib import Path
import sys


def process_data_files(data_directory):
    """
    Process data files and insert the data into the 'plutus.prices' table.

    Args:
        data_directory (str): Path to the directory containing the data files.

    Raises:
        ValueError: If the data directory is invalid.
    """
    if not data_directory.is_dir():
        raise ValueError("Error: Invalid data directory.")

    print("""INSERT INTO plutus.prices
  (data_source_id, name, updated_at, buy, sell, unit)
VALUES""")

    data_sources = []

    for file_path in data_directory.glob('*.json'):
        with file_path.open('r') as file:
            data_array = json.load(file)

        results = defaultdict(lambda: {'MUA': 0, 'BÁN': 0})

        for item in data_array:
            status = ''
            if item['productName'].endswith('MUA'):
                status = 'MUA'
            elif item['productName'].endswith('BÁN'):
                status = 'BÁN'

            results[item['date']][status] += item['price']

        for date_key, prices in results.items():
            data_source_id = 'tygia.io/gia-vang/sjc'
            name = file_path.stem
            updated_at = f"{date_key}T00:00:00+07:00"
            buy_price = prices['MUA']
            sell_price = prices['BÁN']
            unit = 'VNĐ/lượng'
            data_sources.append(f"('{data_source_id}', '{name}', '{updated_at}', {buy_price}, {sell_price}, '{unit}')")

    if not data_sources:
        print("No JSON files found in the specified data directory.")
        sys.exit(1)

    separator = ",\n  "
    print(f"  {separator.join(data_sources)}")
    print("ON CONFLICT DO NOTHING;")


def main():
    """
    Entry point of the script. Parses command-line arguments and processes the data files.
    """
    parser = argparse.ArgumentParser(description='Process data files.')
    parser.add_argument('data_directory', type=str, help='Path to the data directory')
    args = parser.parse_args()

    data_directory = Path(args.data_directory)
    process_data_files(data_directory)


if __name__ == '__main__':
    main()
