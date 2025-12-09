import 'package:flutter/material.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/services/listing_service.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/widgets/common/success_dialog.dart';

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

  Future<void> _fetchWalletBalance() async {
    try {
      if (AuthService.instance.isLoggedIn) {
        await AuthService.instance.fetchProfile();
      }
      if (!mounted) return;

      final user = AuthService.instance.cachedUser;
      if (user != null && user['token_balance'] != null) {
        setState(() {
          _walletBalance = user['token_balance'].toString();
        });
      } else {
        setState(() {
          _walletBalance = '0.00';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletBalance = 'Error';
        });
      }
    }
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ListingService.instance.buyProduct(widget.listing.id);
      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Close purchase dialog with success result

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            message:
                '${LanguageService.instance.t("purchaseSuccess")} ${widget.listing.quantity?.toStringAsFixed(2) ?? ""}kg ${LanguageService.instance.t(widget.listing.title)}. ${LanguageService.instance.t("fundsInEscrow")}',
            onDismiss: () => Navigator.of(context).pop(),
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

    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 2),
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/payments.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  alignment: Alignment.center,
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
                      Text(
                        LanguageService.instance.t('walletBalance'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  LanguageService.instance.t('cancelPurchase'),
                                ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  '${LanguageService.instance.t("pay")} ₹${totalCost.toStringAsFixed(2)}',
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
      },
    );
  }
}
