import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/train_search_model.dart';

class TrainPassengersSheet extends StatefulWidget {
  final TrainPassengers initialPassengers;

  const TrainPassengersSheet({
    super.key,
    required this.initialPassengers,
  });

  static Future<TrainPassengers?> show(
    BuildContext context, {
    required TrainPassengers passengers,
  }) {
    return showModalBottomSheet<TrainPassengers>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrainPassengersSheet(initialPassengers: passengers),
    );
  }

  @override
  State<TrainPassengersSheet> createState() => _TrainPassengersSheetState();
}

class _TrainPassengersSheetState extends State<TrainPassengersSheet> {
  late int _adults;
  late int _children;
  late int _seniors;
  late int _students;
  late int _unionMembers;

  @override
  void initState() {
    super.initState();
    _adults = widget.initialPassengers.adults;
    _children = widget.initialPassengers.children;
    _seniors = widget.initialPassengers.seniors;
    _students = widget.initialPassengers.students;
    _unionMembers = widget.initialPassengers.unionMembers;
  }

  int get _total => _adults + _children + _seniors + _students + _unionMembers;

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int count,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    String? discountBadge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (discountBadge != null) ...[
                            const SizedBox(width: AppDimensions.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                discountBadge,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: count > min ? () => onChanged(count - 1) : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: count > min ? AppColors.neutral100 : AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 18,
                    color: count > min ? AppColors.neutral800 : AppColors.neutral300,
                  ),
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: (count < max && _total < 10) ? () => onChanged(count + 1) : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (count < max && _total < 10) ? AppColors.neutral100 : AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 18,
                    color: (count < max && _total < 10) ? AppColors.neutral800 : AppColors.neutral300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXl),
          topRight: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.md,
        AppDimensions.base,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đối tượng hành khách tàu hỏa',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppDimensions.sm),

          Text(
            'CHỌN ĐỐI TƯỢNG VÉ (Tối đa 10 vé)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),

          _buildCounterRow(
            title: 'Người lớn',
            subtitle: 'Hành khách tiêu chuẩn',
            count: _adults,
            min: 0,
            max: 10,
            onChanged: (val) => setState(() => _adults = val),
          ),
          _buildCounterRow(
            title: 'Trẻ em',
            subtitle: 'Từ 6 đến 10 tuổi (theo năm sinh)',
            count: _children,
            min: 0,
            max: 10,
            discountBadge: 'Giảm 25%',
            onChanged: (val) => setState(() => _children = val),
          ),
          _buildCounterRow(
            title: 'Người cao tuổi',
            subtitle: 'Từ 60 tuổi trở lên (xuất trình CCCD)',
            count: _seniors,
            min: 0,
            max: 10,
            discountBadge: 'Giảm 15%',
            onChanged: (val) => setState(() => _seniors = val),
          ),
          _buildCounterRow(
            title: 'Sinh viên',
            subtitle: 'Các trường ĐH, CĐ (xuất trình Thẻ SV)',
            count: _students,
            min: 0,
            max: 10,
            discountBadge: 'Giảm 10%',
            onChanged: (val) => setState(() => _students = val),
          ),
          _buildCounterRow(
            title: 'Đoàn viên công đoàn',
            subtitle: 'Có thẻ đoàn viên chính thức',
            count: _unionMembers,
            min: 0,
            max: 10,
            discountBadge: 'Giảm 5%',
            onChanged: (val) => setState(() => _unionMembers = val),
          ),

          const SizedBox(height: AppDimensions.lg),

          CustomButton(
            text: 'ÁP DỤNG (${_total > 0 ? _total : 1} VÉ)',
            width: double.infinity,
            type: ButtonType.primary,
            onPressed: () {
              final finalAdults = _total == 0 ? 1 : _adults;
              Navigator.of(context).pop(TrainPassengers(
                adults: finalAdults,
                children: _children,
                seniors: _seniors,
                students: _students,
                unionMembers: _unionMembers,
              ));
            },
          ),
        ],
      ),
    );
  }
}
