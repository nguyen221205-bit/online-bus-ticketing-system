import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/data/models/flight_search_model.dart';

class SelectAirportSheet extends StatefulWidget {
  final String title;
  final List<AirportModel> airports;
  final AirportModel? currentAirport;

  const SelectAirportSheet({
    super.key,
    required this.title,
    required this.airports,
    this.currentAirport,
  });

  static Future<AirportModel?> show(
    BuildContext context, {
    required String title,
    required List<AirportModel> airports,
    AirportModel? currentAirport,
  }) {
    return showModalBottomSheet<AirportModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectAirportSheet(
        title: title,
        airports: airports,
        currentAirport: currentAirport,
      ),
    );
  }

  @override
  State<SelectAirportSheet> createState() => _SelectAirportSheetState();
}

class _SelectAirportSheetState extends State<SelectAirportSheet> {
  late TextEditingController _searchController;
  List<AirportModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.airports;
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
        _filtered = widget.airports;
      } else {
        _filtered = widget.airports.where((a) {
          return a.name.toLowerCase().contains(query) ||
              a.fullName.toLowerCase().contains(query) ||
              a.city.toLowerCase().contains(query) ||
              a.id.toLowerCase().contains(query);
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
                Text(
                  widget.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
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
              hintText: 'Tìm theo mã sân bay, tên thành phố (SGN, HAN, Đà Nẵng...)',
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
                final airport = _filtered[index];
                final isSelected = widget.currentAirport?.id == airport.id;

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
                    child: Text(
                      airport.id,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    airport.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.neutral900,
                    ),
                  ),
                  subtitle: Text(
                    airport.fullName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () => Navigator.of(context).pop(airport),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
