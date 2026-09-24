import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/flight_search_model.dart';

class FlightPassengersSheet extends StatefulWidget {
  final FlightSeatClass initialSeatClass;
  final FlightPassengers initialPassengers;

  const FlightPassengersSheet({
    super.key,
    required this.initialSeatClass,
    required this.initialPassengers,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required FlightSeatClass seatClass,
    required FlightPassengers passengers,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FlightPassengersSheet(
        initialSeatClass: seatClass,
        initialPassengers: passengers,
      ),
    );
  }

  @override
  State<FlightPassengersSheet> createState() => _FlightPassengersSheetState();
}

class _FlightPassengersSheetState extends State<FlightPassengersSheet> {
  late FlightSeatClass _seatClass;
  late int _adults;
  late int _children;
  late int _infants;

  @override
  void initState() {
    super.initState();
    _seatClass = widget.initialSeatClass;
    _adults = widget.initialPassengers.adults;
    _children = widget.initialPassengers.children;
    _infants = widget.initialPassengers.infants;
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int count,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
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
                onTap: count < max ? () => onChanged(count + 1) : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: count < max ? AppColors.neutral100 : AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 18,
                    color: count < max ? AppColors.neutral800 : AppColors.neutral300,
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
                'Hạng ghế & Hành khách bay',
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

          // Hạng ghế (Seat class)
          Text(
            'HẠNG GHẾ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Wrap(
            spacing: AppDimensions.sm,
            runSpacing: AppDimensions.xs,
            children: FlightSeatClass.values.map((cls) {
              final isSelected = _seatClass == cls;
              return ChoiceChip(
                label: Text(cls.label),
                selected: isSelected,
                selectedColor: AppColors.primaryLight,
                backgroundColor: AppColors.neutral50,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.neutral700,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.neutral200,
                ),
                onSelected: (val) {
                  if (val) setState(() => _seatClass = cls);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppDimensions.base),
          const Divider(),
          const SizedBox(height: AppDimensions.sm),

          // Hành khách theo 3 nhóm tuổi
          Text(
            'HÀNH KHÁCH',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          _buildCounterRow(
            title: 'Người lớn',
            subtitle: '> 12 tuổi',
            count: _adults,
            min: 1,
            max: 9,
            onChanged: (val) {
              setState(() {
                _adults = val;
                if (_infants > _adults) _infants = _adults;
              });
            },
          ),
          _buildCounterRow(
            title: 'Trẻ em',
            subtitle: 'Từ 2 đến 12 tuổi',
            count: _children,
            min: 0,
            max: 4,
            onChanged: (val) => setState(() => _children = val),
          ),
          _buildCounterRow(
            title: 'Em bé',
            subtitle: 'Dưới 2 tuổi (ngồi chung ghế người lớn)',
            count: _infants,
            min: 0,
            max: _adults,
            onChanged: (val) => setState(() => _infants = val),
          ),

          const SizedBox(height: AppDimensions.lg),

          CustomButton(
            text: 'ÁP DỤNG',
            width: double.infinity,
            type: ButtonType.primary,
            onPressed: () {
              Navigator.of(context).pop({
                'seatClass': _seatClass,
                'passengers': FlightPassengers(
                  adults: _adults,
                  children: _children,
                  infants: _infants,
                ),
              });
            },
          ),
        ],
      ),
    );
  }
}
