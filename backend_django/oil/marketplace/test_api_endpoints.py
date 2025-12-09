
import os
import sys
import django
from django.core.files.uploadedfile import SimpleUploadedFile
import json

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_marketplace.settings')
django.setup()

from rest_framework.test import APIRequestFactory, force_authenticate
from rest_framework import status
from api.views import CreateproductAPIView, SeedMarketView
from api.models import ESP32Reading, Product
from django.contrib.auth.models import User

def run_tests():
    print("Setting up test data...")
    # Create User
    user, created = User.objects.get_or_create(username='test_api_user')
    if created:
        user.set_password('testpass123')
        user.save()
    
    # Create ESP32 Reading to provide a score
    ESP32Reading.objects.create(
        weight=10, moisture=5, volume=10, density=1, 
        r=255, g=255, b=255, score=95.5
    )
    print("Latest ESP32 Score set to 95.5")

    factory = APIRequestFactory()

    # --- Test 1: Create Product ---
    print("\n--- Testing Create Product API ---")
    
    # Minimal valid 1x1 JPEG
    jpeg_header = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\db\x00C\x01\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xc0\x00\x11\x08\x00\x01\x00\x01\x03\x01\x22\x00\x02\x11\x01\x03\x11\x01\xff\xc4\x00\x15\x00\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xc4\x00\x14\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xc4\x00\x14\x11\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00?\x00\xbf\xff\xd9'

    image_file = SimpleUploadedFile("test_image.jpg", jpeg_header, content_type="image/jpeg")
    cert_file = SimpleUploadedFile("test_cert.pdf", b"file_content", content_type="application/pdf")

    data = {
        'type': 'seeds',
        'product_name': 'Test Seed Product',
        'date_of_listing': '2025-01-01',
        'amount_kg': 100,
        'market_price_per_kg_inr': 50,
        'location': 'Punjab',
        'quality': 'good',
        'image': image_file,
        'certificate': cert_file
    }

    request = factory.post('/api/create/', data, format='multipart')
    force_authenticate(request, user=user)
    view = CreateproductAPIView.as_view()
    response = view(request)

    print(f"Status Code: {response.status_code}")
    if response.status_code == status.HTTP_201_CREATED:
        print("Success! Response Data:")
        # Manually render if needed or just print data
        print(response.data)
        if response.data.get('score') == 95.5:
            print("✅ CHECK PASS: Score 95.5 returned in response.")
        else:
            print(f"❌ CHECK FAIL: Expected score 95.5, got {response.data.get('score')}")
    else:
        print(f"Failed. Errors: {response.data}")

    # --- Test 2: Market View ---
    print("\n--- Testing Seed Market API ---")
    request = factory.get('/api/market/seeds/')
    force_authenticate(request, user=user)
    view = SeedMarketView.as_view()
    response = view(request)

    print(f"Status Code: {response.status_code}")
    if response.status_code == status.HTTP_200_OK:
        data = response.data
        # Find our product
        found = False
        for item in data:
            if item['product_name'] == 'Test Seed Product':
                found = True
                print(f"Found Product. Score: {item.get('score')}")
                if item.get('score') == 95.5:
                    print("✅ CHECK PASS: Score 95.5 found in listing.")
                else:
                    print(f"❌ CHECK FAIL: Score mismatch in market view.")
                break
        if not found:
             print("❌ CHECK FAIL: Created product not found in market view.")
    else:
        print(f"Failed to fetch market. Status: {response.status_code}")

if __name__ == "__main__":
    try:
        run_tests()
    except Exception as e:
        print(f"An error occurred: {e}")
        import traceback
        traceback.print_exc()
