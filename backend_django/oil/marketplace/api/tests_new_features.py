from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from .models import Product, UserProfile
from unittest.mock import patch, MagicMock

class NewFeaturesTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "password": "password123",
            "mobile_no": "1234567890",
            "state": "Test State"
        }
        
    @patch('api.views.web3')
    @patch('api.views.token_contract')
    @patch('api.views.Account')
    def test_registration_with_state(self, mock_account, mock_token_contract, mock_web3):
        # Mock blockchain interactions
        mock_account.create.return_value.address = "0x123"
        mock_account.create.return_value.key.hex.return_value = "0xabc"
        mock_web3.to_wei.return_value = 1000
        mock_web3.eth.get_transaction_count.return_value = 0
        mock_web3.eth.account.sign_transaction.return_value.raw_transaction = b'raw_tx'
        mock_web3.eth.send_raw_transaction.return_value.hex.return_value = "0xtxhash"

        response = self.client.post('/api/register/', self.user_data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        user = User.objects.get(username="testuser")
        profile = UserProfile.objects.get(user=user)
        self.assertEqual(profile.state, "Test State")

    def test_product_creation_with_location_quality(self):
        # Create user and login
        user = User.objects.create_user(username="seller", email="seller@example.com", password="password")
        self.client.force_authenticate(user=user)
        
        product_data = {
            "type": "seeds",
            "product_name": "Test Seeds",
            "date_of_listing": "2023-10-27",
            "amount_kg": 100,
            "market_price_per_kg_inr": 50,
            "location": "Farm Location",
            "quality": "good"
        }
        
        response = self.client.post('/api/create/', product_data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['location'], "Farm Location")
        self.assertEqual(response.data['quality'], "good")
        
        product = Product.objects.get(product_name="Test Seeds")
        self.assertEqual(product.location, "Farm Location")
        self.assertEqual(product.quality, "good")

    def test_market_listing_contains_new_fields(self):
        user = User.objects.create_user(username="seller", email="seller@example.com", password="password")
        Product.objects.create(
            owner=user,
            type="seeds",
            product_name="Market Seeds",
            date_of_listing="2023-10-27",
            amount_kg=100,
            market_price_per_kg_inr=50,
            location="Market Location",
            quality="mid"
        )
        
        self.client.force_authenticate(user=user)
        response = self.client.get('/api/market/seeds/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['location'], "Market Location")
        self.assertEqual(response.data[0]['quality'], "mid")

    @patch('api.views.web3')
    @patch('api.views.token_contract')
    @patch('api.views.escrow_contract')
    def test_insufficient_funds_purchase(self, mock_escrow, mock_token, mock_web3):
        user = User.objects.create_user(username="buyer", email="buyer@example.com", password="password")
        seller = User.objects.create_user(username="seller2", email="seller2@example.com", password="password")
        UserProfile.objects.create(user=user, wallet_address="0xbuyer", private_key="0xkey")
        
        product = Product.objects.create(
            owner=seller,
            type="seeds",
            product_name="Expensive Seeds",
            date_of_listing="2023-10-27",
            amount_kg=10,
            market_price_per_kg_inr=1000, # Total 10000
            location="Market Location",
            quality="mid"
        )
        
        self.client.force_authenticate(user=user)
        
        # Mock balance to be less than required
        mock_token.functions.balanceOf.return_value.call.return_value = 0 # 0 balance
        mock_web3.to_wei.side_effect = lambda x, y: int(x * 10**18) if y == 'ether' else x
        
        response = self.client.post('/api/buy/', {'product_id': product.id})
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error'], "Funds not available")
