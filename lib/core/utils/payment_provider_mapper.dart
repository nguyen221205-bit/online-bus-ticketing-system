/// Utility to map frontend payment method IDs to backend-supported payment providers.
///
/// Supported backend providers per endpoint-api.md 5.7 & MySQL enum:
/// - MOMO
/// - ZALOPAY
/// - VNPAY (handles VietQR, domestic ATM Napas, international cards Visa/Mastercard)
abstract class PaymentProviderMapper {
  /// Converts UI payment method identifier to uppercase backend provider string.
  static String toBackendProvider(String? uiMethod) {
    if (uiMethod == null || uiMethod.trim().isEmpty) {
      return 'VNPAY';
    }

    final normalized = uiMethod.trim().toLowerCase();

    switch (normalized) {
      case 'momo':
        return 'MOMO';
      case 'zalopay':
        return 'ZALOPAY';
      case 'vietqr':
      case 'napas':
      case 'visa':
      case 'vnpay':
      case 'mastercard':
      case 'jcb':
        return 'VNPAY';
      case 'cash':
      case 'tien_mat':
        return 'CASH';
      default:
        // If already uppercase backend provider
        final upper = uiMethod.trim().toUpperCase();
        if (upper == 'MOMO' ||
            upper == 'ZALOPAY' ||
            upper == 'VNPAY' ||
            upper == 'CASH') {
          return upper;
        }
        return 'VNPAY';
    }
  }
}
