import csv
from typing import Dict, List, Any

medicines: List[Dict[str, Any]] = []

columns = [
    "medicine_name",
    "category_name",
    "slug",
    "generic_name",
    "strength",
    "manufacturer_name",
    "unit",
    "unit_size",
    "price"
]


def load_medicines() -> List[Dict[str, Any]]:
    """Load medicines from CSV file and return as a list of dictionaries"""
    global medicines

    if medicines:  # If already loaded, return the cached result
        return medicines

    try:
        with open('../medicine.csv', newline='', encoding='utf-8') as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')

            next(reader)  # Skip header row

            for row in reader:
                if len(row) >= len(columns):
                    try:
                        row[-1] = float(row[-1])
                        row[-2] = int(row[-2]
                                      ) if row[-2].isdigit() else row[-2]
                    except ValueError:
                        pass

                    medicine_dict = {columns[i]: row[i]
                                     for i in range(len(columns))}
                    medicines.append(medicine_dict)
                else:
                    print(f"Skipping row with insufficient data: {row}")

        print(f"Successfully loaded {len(medicines)} medicine entries.")
        return medicines

    except FileNotFoundError:
        print("Error: medicine.csv file not found.")
        return []
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return []


def search_medicine(query: str) -> List[Dict[str, Any]]:
    """Search medicines by name, generic name"""
    global medicines

    # Ensure medicines are loaded
    if not medicines:
        load_medicines()

    query = query.lower()
    return [med for med in medicines if
            query in med["medicine_name"].lower() or
            query in med["generic_name"].lower()]
