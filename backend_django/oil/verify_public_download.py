import requests
import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'marketplace'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_marketplace.settings')
django.setup()

from django.conf import settings
if not settings.configured:
    django.setup()
settings.ALLOWED_HOSTS += ['testserver']

from rest_framework.test import APIClient
from django.contrib.auth.models import User
from certificates.generator import generate_certificate

def verify_public_download():
    print("Setting up test data...")
    user, _ = User.objects.get_or_create(username='test_public_dl', defaults={'first_name': 'Public', 'last_name': 'User'})
    
    # Generate a certificate first (requires auth or internal call)
    # We'll call the generator directly to create a file
    product_data = {
        "commodity": "Public Download Test",
        "date": "05-Dec-2025"
    }
    output_path = generate_certificate(user, product_data=product_data)
    filename = os.path.basename(output_path)
    print(f"Generated certificate: {filename}")
    
    # Test Public Download
    print("Testing Public Download Certificate API...")
    client = APIClient()
    # No authentication provided
    
    response = client.get(f'/api/download-certificate/{filename}/')
    
    if response.status_code == 200:
        print("SUCCESS: Certificate downloaded without authentication")
        if response['Content-Type'] == 'image/jpeg':
            print("Content-Type is correct: image/jpeg")
    else:
        print(f"FAILURE: Download failed with status {response.status_code}")
        print(response.data)

if __name__ == "__main__":
    verify_public_download()
