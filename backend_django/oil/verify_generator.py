import os
import sys
import django

# Setup Django environment
# Add the 'marketplace' directory to sys.path so 'main_marketplace' can be imported
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'marketplace'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'main_marketplace.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile, Product
from certificates.generator import generate_certificate
from datetime import date

def verify():
    print("Setting up test data...")
    # Create or get test user
    user, created = User.objects.get_or_create(username='test_gen_user', defaults={'first_name': 'Test', 'last_name': 'User'})
    if created:
        user.set_password('password')
        user.save()
        print(f"Created user: {user.username}")
    else:
        print(f"Using existing user: {user.username}")

    # Create or get user profile
    profile, created = UserProfile.objects.get_or_create(user=user, defaults={'state': 'Test State', 'mobile_no': '1234567890'})
    if created:
        print("Created user profile")
    else:
        print("Using existing user profile")

    # Create or get test product
    product, created = Product.objects.get_or_create(
        product_name='Test Commodity',
        owner=user,
        defaults={
            'type': 'seeds',
            'date_of_listing': date.today(),
            'amount_kg': 100,
            'quality': 'good'
        }
    )
    if created:
        print(f"Created product: {product.product_name}")
    else:
        print(f"Using existing product: {product.product_name}")

    print("Running generate_certificate...")
    try:
        output_path = generate_certificate(user, product.id)
        if os.path.exists(output_path):
            print(f"SUCCESS: Certificate generated at {output_path}")
        else:
            print(f"FAILURE: Output file not found at {output_path}")
    except Exception as e:
        print(f"FAILURE: Exception occurred: {e}")

if __name__ == "__main__":
    verify()
