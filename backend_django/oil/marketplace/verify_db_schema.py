
import os
import sys
import django
from django.db import connection

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_marketplace.settings')
django.setup()

from api.models import Product, ESP32Reading

def check_columns(table_name):
    print(f"\nChecking table: {table_name}")
    with connection.cursor() as cursor:
        try:
            cursor.execute(f"SELECT * FROM {table_name} LIMIT 0")
            col_names = [desc[0] for desc in cursor.description]
            print(f"Columns: {col_names}")
            if 'score' in col_names:
                print(" -> 'score' column FOUND.")
            else:
                print(" -> 'score' column MISSING!")
        except Exception as e:
            print(f"Error checking table {table_name}: {e}")

def check_data():
    print("\nChecking ESP32Reading data...")
    try:
        latest = ESP32Reading.objects.latest('timestamp')
        print(f"Latest reading found: ID={latest.id}, Score={latest.score}")
    except ESP32Reading.DoesNotExist:
        print("No ESP32Reading data found (empty table).")
    except Exception as e:
        print(f"Error fetching ESP32Reading: {e}")

if __name__ == "__main__":
    check_columns("api_product")
    check_columns("api_esp32reading")
    check_data()
