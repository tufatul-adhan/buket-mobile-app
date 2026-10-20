import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final String? label;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;

  const CustomTextField({
    Key? key,
    required this.hintText,
    this.label,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.isPassword = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscurePassword;

  @override
  void initState() {
    super.initState();
    _obscurePassword = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscurePassword,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.label,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondaryColor,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              )
            : null,
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String? hintText;
  final String? label;
  final IconData? prefixIcon;
  final List<String> items;
  final String? value;
  final Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool isCityPicker;

  const CustomDropdown({
    Key? key,
    this.hintText,
    this.label,
    this.prefixIcon,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.isCityPicker = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCityPicker) {
      return CityPickerField(
        hintText: hintText,
        label: label,
        prefixIcon: prefixIcon,
        items: items,
        value: value,
        onChanged: onChanged,
        validator: validator,
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}

class CityPickerField extends StatefulWidget {
  final String? hintText;
  final String? label;
  final IconData? prefixIcon;
  final List<String> items;
  final String? value;
  final Function(String?)? onChanged;
  final String? Function(String?)? validator;

  const CityPickerField({
    Key? key,
    this.hintText,
    this.label,
    this.prefixIcon,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<CityPickerField> createState() => _CityPickerFieldState();
}

class _CityPickerFieldState extends State<CityPickerField> {
  late String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.value;
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CityPickerBottomSheet(
        cities: widget.items,
        selectedCity: _selectedCity,
        onCitySelected: (city) {
          setState(() => _selectedCity = city);
          widget.onChanged?.call(city);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _selectedCity,
      validator: widget.validator,
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: _showCityPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: field.hasError ? Colors.red : Colors.grey[300]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Icon(
                        widget.prefixIcon,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        _selectedCity ?? widget.hintText ?? 'Pilih kota',
                        style: TextStyle(
                          color: _selectedCity != null
                              ? Colors.grey[800]
                              : Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText ?? '',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class CityPickerBottomSheet extends StatefulWidget {
  final List<String> cities;
  final String? selectedCity;
  final Function(String) onCitySelected;

  const CityPickerBottomSheet({
    Key? key,
    required this.cities,
    this.selectedCity,
    required this.onCitySelected,
  }) : super(key: key);

  @override
  State<CityPickerBottomSheet> createState() => _CityPickerBottomSheetState();
}

class _CityPickerBottomSheetState extends State<CityPickerBottomSheet> {
  late List<String> _filteredCities;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.cities;
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    setState(() {
      _filteredCities = widget.cities
          .where((city) =>
              city.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Kota Anda',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kami melayani ${widget.cities.length} kota di area Jakarta dan sekitarnya',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        // Search Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari kota...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _filteredCities = widget.cities);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // City List
        Flexible(
          child: _filteredCities.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kota tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCities.length,
                  itemBuilder: (context, index) {
                    final city = _filteredCities[index];
                    final isSelected = widget.selectedCity == city;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onCitySelected(city),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? AppTheme.softColor : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      city,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? AppTheme.primaryDark
                                                : Colors.grey[800],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;

  const PrimaryButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double? width;

  const SecondaryButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 54,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final double rating;
  final int reviews;
  final String category;
  final VoidCallback onTap;
  final Widget? image;

  const ProductCard({
    Key? key,
    required this.name,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.category,
    required this.onTap,
    this.image,
  }) : super(key: key);

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Container(
              width: double.infinity,
              height: 176,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                color: AppTheme.softColor,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.softColor,
                    AppTheme.softColor,
                  ],
                ),
              ),
              child: image ??
                  Icon(
                    Icons.local_florist,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviews)',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.softColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      _formatPrice(price),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.primaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Coba Lagi',
              onPressed: onRetry,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ],
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('Lihat Semua'),
            ),
        ],
      ),
    );
  }
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    Key? key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            onPressed: quantity > 1 ? onDecrement : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                quantity.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
