import cv2
import os
from datetime import date
from api.models import UserProfile, Product, ESP32Reading

def get_esp32_data(product_id):
    """
    Fetches the latest data from ESP32Reading table.
    """
    try:
        reading = ESP32Reading.objects.latest('timestamp')
        
        # Check if data is fresh (e.g., within last 5 minutes)
        from django.utils import timezone
        import datetime
        
        time_diff = timezone.now() - reading.timestamp
        if time_diff.total_seconds() > 300: # 5 minutes
             raise ESP32Reading.DoesNotExist # Treat as no data
             
        return {
            "weight": reading.weight,
            "moisture": reading.moisture,
            "volume": reading.volume,
            "density": reading.density,
            "r": reading.r,
            "g": reading.g,
            "b": reading.b,
            "score": reading.score
        }
    except ESP32Reading.DoesNotExist:
        # Fallback if no data exists
        return {
            "weight": 0,
            "moisture": 0,
            "volume": 0,
            "density": 0,
            "r": 0,
            "g": 0,
            "b": 0,
            "score": 0
        }

def generate_certificate(user, product_id=None, product_data=None):
    """
    Generates a certificate for a given user.
    Can use either a product_id (fetch from DB) or product_data (manual input).
    """
    # -------------------------------
    # Fetch Data
    # -------------------------------
    # User Details
    try:
        user_profile = UserProfile.objects.get(user=user)
        location = user_profile.state if user_profile.state else "Unknown"
    except UserProfile.DoesNotExist:
        location = "Unknown"
    
    user_name = user.get_full_name()
    if not user_name:
        user_name = user.username

    # Product Details
    if product_data:
        # Manual Input
        commodity = product_data.get("commodity", "Unknown")
        date_str = product_data.get("date", date.today().strftime("%d-%b-%Y"))
        # Generate a pseudo batch number or use provided
        batch_no = product_data.get("batch_no", f"BATCH-{date.today().strftime('%Y%m%d')}")
        # Use a dummy ID for filename if not provided
        p_id_for_filename = "manual"
    elif product_id:
        # Fetch from DB
        try:
            product_obj = Product.objects.get(id=product_id)
            commodity = product_obj.product_name
            batch_no = f"BATCH-{product_obj.id:04d}"
            date_str = product_obj.date_of_listing.strftime("%d-%b-%Y")
            p_id_for_filename = str(product_id)
        except Product.DoesNotExist:
            raise ValueError(f"Product with id {product_id} not found")
    else:
        raise ValueError("Either product_id or product_data must be provided")

    # ESP32 Data (Placeholder)
    # In a real scenario, we might pass product_id to the API if available
    esp_data = get_esp32_data(product_id if product_id else 0)

    # Constant/Auth Details
    tested_by = "IoT Quality Analyzer v1.0"
    auth_name = "Dr. Amit"
    designation = "Chief Quality Officer"
    sign_date = date.today().strftime("%d-%b-%Y")

    # -------------------------------
    # Load JPG template
    # -------------------------------
    # Assuming the template is in the same directory as this script
    base_dir = os.path.dirname(os.path.abspath(__file__))
    template_path = os.path.join(base_dir, "certificate_updated.jpg")
    img = cv2.imread(template_path)

    if img is None:
        # Fallback to current working directory if not found in script dir
        img = cv2.imread("certificate_updated.jpg")
        if img is None:
            raise FileNotFoundError(f"Could not load certificate_template.jpg from {template_path} or CWD")

    # Create output folder if not exists
    output_dir = os.path.join(base_dir, "generated_certificates")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # -------------------------------
    # Text appearance settings
    # -------------------------------
    font = cv2.FONT_HERSHEY_SIMPLEX
    scale = 0.5
    color = (0, 0, 0)   # Black text
    thick = 2

    # -------------------------------
    # USER DETAILS (adjust coordinates!)
    # -------------------------------
    cv2.putText(img, user_name,     (172,608), font, scale, color, thick)
    cv2.putText(img, location,      (141,633), font, scale, color, thick)

    # -------------------------------
    # PRODUCT DETAILS
    # -------------------------------
    cv2.putText(img, commodity,     (166,659), font, scale, color, thick)
    cv2.putText(img, batch_no,      (190,684), font, scale, color, thick)
    cv2.putText(img, date_str,      (180,709), font, scale, color, thick)

    cv2.putText(img, str(esp_data["weight"]),   (153,770), font, scale, color, thick)
    cv2.putText(img, str(esp_data["moisture"]), (169,796), font, scale, color, thick)
    cv2.putText(img, str(esp_data["volume"]),   (171,821), font, scale, color, thick)
    cv2.putText(img, str(esp_data["density"]),  (184,846), font, scale, color, thick)

    rgb_text = f'{esp_data["r"]}, {esp_data["g"]}, {esp_data["b"]}'
    cv2.putText(img, rgb_text, (169,867), font, scale, color, thick)

    cv2.putText(img, str(esp_data["score"]), (272,894), font, scale, color, thick)

    # -------------------------------
    # AUTHORIZATION BLOCK
    # -------------------------------
    cv2.putText(img, tested_by,   (169,1008), font, scale, color, thick)
    cv2.putText(img, auth_name,   (588,1135), font, scale, color, thick)
    cv2.putText(img, designation, (630,1160), font, scale, color, thick)
    cv2.putText(img, sign_date,   (577,1185), font, scale, color, thick)

    # -------------------------------
    # Save final output
    # -------------------------------
    output_filename = f"certificate_{p_id_for_filename}_{user.username}.jpg"
    output_path = os.path.join(output_dir, output_filename)
    cv2.imwrite(output_path, img)

    print("✔ Certificate generated at:", output_path)
    return output_path

# --------------------------------------------------------
# Example usage (Requires Django Environment)
# --------------------------------------------------------
if __name__ == "__main__":
    import sys
    import django
    
    # Add project root to sys.path
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    sys.path.append(project_root)
    
    # Set Django settings module
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'oil.settings') # Assuming 'oil' is the project name
    django.setup()

    from django.contrib.auth.models import User
    
    # Try to get a user and product for testing
    try:
        test_user = User.objects.first()
        test_product = Product.objects.first()
        
        if test_user and test_product:
            print(f"Generating certificate for User: {test_user.username}, Product: {test_product.product_name}")
            generate_certificate(test_user, test_product.id)
        else:
            print("No user or product found for testing.")
    except Exception as e:
        print(f"Error during test run: {e}")
