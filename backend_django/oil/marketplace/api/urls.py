from .views import register, login, logout, profile, CreateproductAPIView, SeedListingAPIView, ByproductListingAPIView, SeedMarketView, ByproductMarketView, BuyProductView, ConfirmReceiptView, RefundView, MyOrdersView, GenerateCertificateView, DownloadCertificateView, ESP32DataView
from django.urls import path

urlpatterns=[
    path("register/",register),
    path("login/",login),
    path("profile/",profile),
    path("logout/",logout),
    path("create/",CreateproductAPIView.as_view()),
    path("seed/",SeedListingAPIView.as_view()),
    path("byproduct/",ByproductListingAPIView.as_view()),
    path("market/seeds/",SeedMarketView.as_view()),
    path("market/byproducts/",ByproductMarketView.as_view()),
    path("buy/",BuyProductView.as_view()),
    path("confirm/",ConfirmReceiptView.as_view()),
    path("refund/",RefundView.as_view()),
    path("orders/",MyOrdersView.as_view()),
    path("generate-certificate/", GenerateCertificateView.as_view()),
    path("download-certificate/<str:filename>/", DownloadCertificateView.as_view()),
    path("esp32-data/", ESP32DataView.as_view()),
]