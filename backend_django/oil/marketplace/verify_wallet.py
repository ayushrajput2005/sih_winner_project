import os
import django
import sys

# Setup Django environment
sys.path.append('/Users/srujan/Desktop/oil/marketplace')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_marketplace.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile
from rest_framework.test import APIRequestFactory
from api.views import register
import json

def verify_wallet_creation():
    # Cleanup previous test user if exists
    username = "testuser_wallet"
    email = "testuser_wallet@example.com"
    try:
        u = User.objects.get(username=username)
        u.delete()
        print(f"Deleted existing user {username}")
    except User.DoesNotExist:
        pass

    # Create request
    factory = APIRequestFactory()
    data = {
        "username": username,
        "email": email,
        "password": "password123",
        "mobile_no": "1234567890"
    }
    request = factory.post('/api/register/', data, format='json')
    
    # Call view
    print("Calling register view...")
    response = register(request)
    
    if response.status_code == 200:
        print("Registration successful")
        
        # Verify wallet
        user = User.objects.get(username=username)
        profile = UserProfile.objects.get(user=user)
        
        print(f"Wallet Address: {profile.wallet_address}")
        print(f"Private Key: {profile.private_key}")
        
        if profile.wallet_address and profile.private_key:
            print("SUCCESS: Wallet created and stored.")
        else:
            print("FAILURE: Wallet details missing.")
    else:
        print(f"Registration failed: {response.data}")

if __name__ == "__main__":
    verify_wallet_creation()
