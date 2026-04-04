import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/enterprise_card.dart';
import '../../widgets/status_badge.dart';

class KioskScreen extends StatelessWidget {
  const KioskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white, // Kiosk is often full screen white/light
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCameraFeed(context),
              const SizedBox(height: 32),
              _buildLiveLog(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Trạm Kiosk Chấm công'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppTheme.backgroundLight,
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          '07:45 AM',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppTheme.corporateBlue,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thứ Tư, 14/10/2026',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cửa Chính - Đang hoạt động',
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFeed(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        boxShadow: AppTheme.softShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'CAMERA TRỰC TIẾP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            // Facial Recognition Frame (Mockup)
            Positioned(
              child: Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.corporateBlue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Stack(
                  children: [
                    Positioned(top: 8, left: 8, child: _CornerMarker()),
                    Positioned(top: 8, right: 8, child: _CornerMarker()),
                    Positioned(bottom: 8, left: 8, child: _CornerMarker()),
                    Positioned(bottom: 8, right: 8, child: _CornerMarker()),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      '1. Đưa mã QR vào máy quét -> 2. Nhìn thẳng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chấm công thành công: Nguyễn Văn A'),
                          backgroundColor: AppTheme.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.corporateBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('GIẢ LẬP QUÉT MẶT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: AppTheme.textPrimary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Nhật ký Live Log',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        EnterpriseCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildLogItem('07:44', 'Trần Văn B', BadgeType.success),
              const Divider(),
              _buildLogItem('07:43', 'Lê Thị C', BadgeType.success),
              const Divider(),
              _buildLogItem(
                '07:42',
                'Cảnh báo: Không khớp mặt',
                BadgeType.error,
                isAlert: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(
    String time,
    String message,
    BadgeType badgeType, {
    bool isAlert = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isAlert ? AppTheme.error : AppTheme.textPrimary,
              ),
            ),
          ),
          StatusBadge(text: isAlert ? 'Thất bại' : 'Hợp lệ', type: badgeType),
        ],
      ),
    );
  }
}

class _CornerMarker extends StatelessWidget {
  const _CornerMarker();

  @override
  Widget build(BuildContext context) {
    return Container(width: 16, height: 16, color: AppTheme.corporateBlue);
  }
}
