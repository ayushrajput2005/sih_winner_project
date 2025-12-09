from rest_framework import serializers
from .models import Product

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model=Product
        fields="__all__"
        read_only_fields=["owner"]

from .models import ESP32Reading
class ESP32ReadingSerializer(serializers.ModelSerializer):
    class Meta:
        model = ESP32Reading
        fields = '__all__'
