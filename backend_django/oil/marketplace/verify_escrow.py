import os
import django
import sys
import json
import time

# Setup Django environment
sys.path.append('/Users/srujan/Desktop/oil/marketplace')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_marketplace.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile, Product, Order
from rest_framework.test import APIRequestFactory, force_authenticate
from api.views import register, login, profile, BuyProductView, ConfirmReceiptView, RefundView, CreateproductAPIView
from blockchain.web3_setup import web3, token_contract, escrow_contract

def verify_escrow_flow():
    factory = APIRequestFactory()
    
    # 1. Setup Users
    buyer_username = "buyer_test"
    seller_username = "seller_test"
    password = "password123"
    
    # Cleanup
    User.objects.filter(username__in=[buyer_username, seller_username]).delete()
    print("Cleaned up old users.")

    # Register Buyer
    print("\n--- Registering Buyer ---")
    req_reg = factory.post('/api/register/', {"username": buyer_username, "email": "buyer@test.com", "password": password, "mobile_no": "1111111111"}, format='json')
    resp_reg = register(req_reg)
    print(f"Buyer Reg: {resp_reg.status_code}")
    
    # Register Seller
    print("\n--- Registering Seller ---")
    req_reg = factory.post('/api/register/', {"username": seller_username, "email": "seller@test.com", "password": password, "mobile_no": "2222222222"}, format='json')
    resp_reg = register(req_reg)
    print(f"Seller Reg: {resp_reg.status_code}")

    # Wait for premint txs to confirm (simulated wait)
    print("Waiting for premint transactions...")
    time.sleep(5) 

    buyer_user = User.objects.get(username=buyer_username)
    seller_user = User.objects.get(username=seller_username)
    
    # Check Buyer Balance
    buyer_profile = UserProfile.objects.get(user=buyer_user)
    balance_wei = token_contract.functions.balanceOf(buyer_profile.wallet_address).call()
    print(f"Buyer Balance: {web3.from_wei(balance_wei, 'ether')} INR")

    # 2. Create Product (Seller)
    print("\n--- Creating Product ---")
    product_data = {
        "type": "seeds",
        "product_name": "Test Seeds",
        "date_of_listing": "2023-10-27",
        "amount_kg": 100,
        "market_price_per_kg_inr": 10 # Total 1000 INR
    }
    # Use default format (multipart/form-data) for file uploads/form data
    req_create = factory.post('/api/create/', product_data) 
    force_authenticate(req_create, user=seller_user)
    view_create = CreateproductAPIView.as_view()
    resp_create = view_create(req_create)
    print(f"Create Product: {resp_create.status_code}")
    if resp_create.status_code != 201:
        print(f"Create Failed: {resp_create.data}")
        return
    product_id = Product.objects.get(owner=seller_user, product_name="Test Seeds").id


    # 3. Buy Product (Buyer)
    print("\n--- Buying Product ---")
    req_buy = factory.post('/api/buy/', {"product_id": product_id}, format='json')
    force_authenticate(req_buy, user=buyer_user)
    view_buy = BuyProductView.as_view()
    resp_buy = view_buy(req_buy)
    print(f"Buy Response: {resp_buy.data}")
    
    if resp_buy.status_code != 200:
        print("Buy failed, aborting.")
        return

    # Check Escrow Balance
    escrow_bal_wei = escrow_contract.functions.escrowBalance().call()
    print(f"Escrow Balance: {web3.from_wei(escrow_bal_wei, 'ether')} INR")
    
    order = Order.objects.get(buyer=buyer_user, product_id=product_id)
    print(f"Order Status: {order.status}")

    # 4. Confirm Receipt
    print("\n--- Confirming Receipt ---")
    req_confirm = factory.post('/api/confirm/', {"order_id": order.id}, format='json')
    force_authenticate(req_confirm, user=buyer_user)
    view_confirm = ConfirmReceiptView.as_view()
    resp_confirm = view_confirm(req_confirm)
    print(f"Confirm Response: {resp_confirm.data}")
    
    # Check Seller Balance
    seller_profile = UserProfile.objects.get(user=seller_user)
    seller_bal_wei = token_contract.functions.balanceOf(seller_profile.wallet_address).call()
    print(f"Seller Balance: {web3.from_wei(seller_bal_wei, 'ether')} INR")
    
    # 5. Refund Flow (New Product)
    print("\n--- Testing Refund Flow ---")
    # Create another product
    product_data2 = {
        "type": "seeds",
        "product_name": "Refund Seeds",
        "date_of_listing": "2023-10-27",
        "amount_kg": 50,
        "market_price_per_kg_inr": 10 # Total 500 INR
    }
    req_create2 = factory.post('/api/create/', product_data2)
    force_authenticate(req_create2, user=seller_user)
    resp_create2 = view_create(req_create2)
    if resp_create2.status_code != 201:
        print(f"Create 2 Failed: {resp_create2.data}")
        return
    product_id2 = Product.objects.get(owner=seller_user, product_name="Refund Seeds").id

    
    # Buy
    req_buy2 = factory.post('/api/buy/', {"product_id": product_id2}, format='json')
    force_authenticate(req_buy2, user=buyer_user)
    resp_buy2 = view_buy(req_buy2)
    print(f"Buy 2 Response: {resp_buy2.data}")
    
    order2 = Order.objects.get(buyer=buyer_user, product_id=product_id2)
    
    # Refund
    req_refund = factory.post('/api/refund/', {"order_id": order2.id}, format='json')
    force_authenticate(req_refund, user=buyer_user)
    view_refund = RefundView.as_view()
    resp_refund = view_refund(req_refund)
    print(f"Refund Response: {resp_refund.data}")
    
    # Check Buyer Balance (Should be 10000 - 1000 (first buy) + 0 (refunded second buy) = 9000? No wait.
    # Initial: 10000
    # Buy 1: -1000 -> 9000
    # Buy 2: -500 -> 8500
    # Refund 2: +500 -> 9000
    balance_wei_final = token_contract.functions.balanceOf(buyer_profile.wallet_address).call()
    print(f"Final Buyer Balance: {web3.from_wei(balance_wei_final, 'ether')} INR")

if __name__ == "__main__":
    verify_escrow_flow()
