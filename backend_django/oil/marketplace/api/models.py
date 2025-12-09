from django.db import models
from django.contrib.auth.models import User

class Product(models.Model):
    TYPE_CHOICES=(
    ("seeds","Seeds"),
    ("byproduct","Byproduct"),
    )
    QUALITY_CHOICES = (
        ('good', 'Good'),
        ('mid', 'Mid'),
        ('bad', 'Bad'),
    )
    owner=models.ForeignKey(User , on_delete=models.CASCADE)
    type = models.CharField(max_length=20,choices=TYPE_CHOICES)
    product_name=models.CharField(max_length=100)
    date_of_listing=models.DateField()
    certificate=models.FileField(upload_to="certificates/", null=True, blank=True)
    amount_kg=models.DecimalField(max_digits=10,decimal_places=2)

    market_price_per_kg_inr=models.DecimalField(max_digits=10,decimal_places=2,null=True,blank=True)
    image = models.ImageField(upload_to='product_images/', null=True, blank=True)
    location = models.CharField(max_length=100, null=True, blank=True)
    quality = models.CharField(max_length=10, choices=QUALITY_CHOICES, default='mid')
    score = models.FloatField(default=0.0)
    created_at=models.DateTimeField(auto_now_add=True)

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    mobile_no = models.CharField(max_length=15)
    state = models.CharField(max_length=100, null=True, blank=True)
    wallet_address = models.CharField(max_length=42, unique=True, null=True, blank=True)
    private_key = models.CharField(max_length=66, null=True, blank=True)

    def __str__(self):
        return self.user.username

class Order(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('DEPOSITED', 'Deposited'),
        ('COMPLETED', 'Completed'),
        ('REFUNDED', 'Refunded'),
    )
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    amount_token = models.DecimalField(max_digits=20, decimal_places=2) # Amount in INR
    fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    tx_hash_deposit = models.CharField(max_length=66, null=True, blank=True)
    tx_hash_release = models.CharField(max_length=66, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Order {self.id} - {self.product.product_name} - {self.status}"

class ESP32Reading(models.Model):
    weight = models.FloatField()
    moisture = models.FloatField()
    volume = models.FloatField()
    density = models.FloatField()
    r = models.IntegerField()
    g = models.IntegerField()
    b = models.IntegerField()
    score = models.FloatField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Reading {self.id} - {self.timestamp}"
