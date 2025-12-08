import 'package:flutter/material.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/services/listing_service.dart';

class PurchaseDialog extends StatefulWidget {
  final ListingData listing;

  const PurchaseDialog({super.key, required this.listing});

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  bool _isLoading = false;
  String? _walletBalance;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  void _fetchWalletBalance() {
    final user = AuthService.instance.cachedUser;
    if (user != null && user['token_balance'] != null) {
      setState(() {
        _walletBalance = user['token_balance'].toString();
      });
    } else {
      // Fallback or fetch profile again?
      // For now, assuming profile is up to date since we access this only when logged in.
      setState(() {
        _walletBalance = '0.00';
      });
    }
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ListingService.instance.buyProduct(widget.listing.id);
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully purchased ${widget.listing.quantity?.toStringAsFixed(2) ?? ""}kg of ${widget.listing.title}. Funds in Escrow.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total cost
    final totalCost = (widget.listing.price) * (widget.listing.quantity ?? 1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section: Payment Types Img Placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Payment Methods',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Bottom Section: Wallet Balance & Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'Wallet Balance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹ ${_walletBalance ?? "..."}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel Purchase'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handlePurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Pay ₹${totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
