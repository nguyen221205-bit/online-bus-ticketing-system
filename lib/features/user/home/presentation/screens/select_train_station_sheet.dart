import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/data/models/train_search_model.dart';

class SelectTrainStationSheet extends StatefulWidget {
  final String title;
  final List<TrainStationModel> stations;
  final TrainStationModel? currentStation;

  const SelectTrainStationSheet({
    super.key,
    required this.title,
    required this.stations,
    this.currentStation,
  });

  static Future<TrainStationModel?> show(
    BuildContext context, {
    required String title,
    required List<TrainStationModel> stations,
    TrainStationModel? currentStation,
  }) {
    return showModalBottomSheet<TrainStationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectTrainStationSheet(
        title: title,
        stations: stations,
        currentStation: currentStation,
      ),
    );
  }

  @override
  State<SelectTrainStationSheet> createState() => _SelectTrainStationSheetState();
}

class _SelectTrainStationSheetState extends State<SelectTrainStationSheet> {
  late TextEditingController _searchController;
  List<TrainStationModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.stations;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.stations;
      } else {
        _filtered = widget.stations.where((s) {
          return s.name.toLowerCase().contains(query) ||
              s.address.toLowerCase().contains(query) ||
              s.city.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXl),
          topRight: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppDimensions.md, bottom: AppDimensions.xs),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Tìm theo tên ga, địa phương (Ga Sài Gòn, Hà Nội, Nha Trang...)',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neutral400),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              itemCount: _filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final station = _filtered[index];
                final isSelected = widget.currentStation?.id == station.id;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.train_rounded,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    station.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.neutral900,
                    ),
                  ),
                  subtitle: Text(
                    station.address,
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () => Navigator.of(context).pop(station),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
