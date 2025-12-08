import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/services/cart_service.dart';
import 'package:fasalmitra/services/order_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const String routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(LanguageService.instance.t('myCart')),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  CartService.instance.clearCart();
                },
                tooltip: LanguageService.instance.t('clearCart'),
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: CartService.instance,
            builder: (context, _) {
              final items = CartService.instance.items;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        LanguageService.instance.t('cartEmpty'),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Image
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                    image: item.listing.imageUrls.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              item.listing.imageUrls.first,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: item.listing.imageUrls.isEmpty
                                      ? const Icon(Icons.image_not_supported)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.listing.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${item.listing.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Controls
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          CartService.instance.updateQuantity(
                                            item.listing.id,
                                            item.quantity - 1,
                                          );
                                        } else {
                                          CartService.instance.removeFromCart(
                                            item.listing.id,
                                          );
                                        }
                                      },
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {
                                        CartService.instance.updateQuantity(
                                          item.listing.id,
                                          item.quantity + 1,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Total and Checkout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${LanguageService.instance.t('total')}:',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${CartService.instance.totalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () async {
                                try {
                                  await OrderService.instance.createOrder(
                                    CartService.instance.items,
                                    CartService.instance.totalPrice,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          LanguageService.instance.t(
                                            'orderSuccess',
                                          ),
                                        ),
                                      ),
                                    );
                                    CartService.instance.clearCart();
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/my-orders');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${LanguageService.instance.t('orderFailed')}: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                LanguageService.instance.t('checkout'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
