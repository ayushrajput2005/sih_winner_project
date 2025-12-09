import os
import django
import sys
import json

# Setup Django environment
sys.path.append('/Users/srujan/Desktop/oil/marketplace')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_marketplace.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile
from rest_framework.test import APIRequestFactory, force_authenticate
from api.views import register, login, profile

def verify_wallet_and_balance():
    username = "testuser_balance"
    email = "testuser_balance@example.com"
    password = "password123"
    
    # Cleanup
    try:
        u = User.objects.get(username=username)
        u.delete()
        print(f"Deleted existing user {username}")
    except User.DoesNotExist:
        pass

    factory = APIRequestFactory()

    # 1. Register
    print("\n--- Testing Registration ---")
    data_reg = {
        "username": username,
        "email": email,
        "password": password,
        "mobile_no": "1234567890"
    }
    req_reg = factory.post('/api/register/', data_reg, format='json')
    resp_reg = register(req_reg)
    
    if resp_reg.status_code == 200:
        print("Registration successful")
        if 'wallet_address' in resp_reg.data:
            print(f"SUCCESS: Wallet address returned in registration: {resp_reg.data['wallet_address']}")
        else:
            print("FAILURE: Wallet address NOT returned in registration")
    else:
        print(f"Registration failed: {resp_reg.data}")
        return

    # 2. Login
    print("\n--- Testing Login ---")
    data_login = {
        "email": email,
        "password": password
    }
    req_login = factory.post('/api/login/', data_login, format='json')
    resp_login = login(req_login)
    
    token = None
    if resp_login.status_code == 200:
        token = resp_login.data.get('token')
        print("Login successful, token received")
    else:
        print(f"Login failed: {resp_login.data}")
        return

    # 3. Profile
    print("\n--- Testing Profile ---")
    req_profile = factory.get('/api/profile/')
    user = User.objects.get(username=username)
    force_authenticate(req_profile, user=user) # Simulate authentication
    
    resp_profile = profile(req_profile)
    
    if resp_profile.status_code == 200:
        print("Profile fetch successful")
        data = resp_profile.data
        print(f"Wallet Address: {data.get('wallet_address')}")
        print(f"Token Balance: {data.get('token_balance')}")
        
        if 'wallet_address' in data and 'token_balance' in data:
             print("SUCCESS: Wallet address and token balance present in profile.")
        else:
             print("FAILURE: Missing wallet address or token balance in profile.")
    else:
        print(f"Profile fetch failed: {resp_profile.data}")

if __name__ == "__main__":
    verify_wallet_and_balance()
