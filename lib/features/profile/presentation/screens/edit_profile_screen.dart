import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/edit_profile_viewmodel.dart';

class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? driverData;

  const EditProfileScreen({super.key, this.driverData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileViewModel(driverData),
      child: const _EditProfileContent(),
    );
  }
}

class _EditProfileContent extends StatelessWidget {
  const _EditProfileContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vm.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: AppColors.error.withValues(alpha: 0.1),
                        child: Text(vm.error!, style: const TextStyle(color: AppColors.error)),
                      ),
                    
                    _sectionTitle('Personal Details'),
                    _imagePickerTile('Profile Photo', vm.image, (s) => vm.pickImage('image', s)),
                    _textField(label: 'Full Name', initialValue: vm.name, onChanged: (v) => vm.name = v),
                    _textField(label: 'Email', initialValue: vm.email, onChanged: (v) => vm.email = v),
                    _textField(label: 'Phone', initialValue: vm.phone, onChanged: (v) => vm.phone = v),
                    _textField(label: 'Address', initialValue: vm.address, onChanged: (v) => vm.address = v),
                    Row(
                      children: [
                        Expanded(child: _textField(label: 'City', initialValue: vm.city, onChanged: (v) => vm.city = v)),
                        const SizedBox(width: 16),
                        Expanded(child: _textField(label: 'State', initialValue: vm.state, onChanged: (v) => vm.state = v)),
                      ],
                    ),
                    _textField(label: 'Pincode', initialValue: vm.pincode, onChanged: (v) => vm.pincode = v),
                    _textField(label: 'Password (leave blank to keep)', initialValue: vm.password, onChanged: (v) => vm.password = v, obscureText: true),

                    const SizedBox(height: 24),
                    _sectionTitle('KYC Documents'),
                    _textField(label: 'Aadhar Number', initialValue: vm.aadharNumber, onChanged: (v) => vm.aadharNumber = v),
                    _imagePickerTile('Update Aadhar Photo', vm.aadhar, (s) => vm.pickImage('aadhar', s)),
                    _textField(label: 'PAN Number', initialValue: vm.panNumber, onChanged: (v) => vm.panNumber = v),
                    _imagePickerTile('Update PAN Photo', vm.pan, (s) => vm.pickImage('pan', s)),
                    _textField(label: 'Driving License Number', initialValue: vm.licenseNumber, onChanged: (v) => vm.licenseNumber = v),
                    _dateField(context: context, label: 'License Expiry', initialValue: vm.licenseExpiry, onChanged: (v) => vm.licenseExpiry = v),
                    _imagePickerTile('Update License Photo', vm.licenseImage, (s) => vm.pickImage('license', s)),

                    const SizedBox(height: 24),
                    _sectionTitle('Vehicle Details'),
                    _textField(label: 'Car Number', initialValue: vm.carNumber, onChanged: (v) => vm.carNumber = v),
                    Row(
                      children: [
                        Expanded(child: _textField(label: 'Brand', initialValue: vm.carBrand, onChanged: (v) => vm.carBrand = v)),
                        const SizedBox(width: 16),
                        Expanded(child: _textField(label: 'Model', initialValue: vm.carModel, onChanged: (v) => vm.carModel = v)),
                      ],
                    ),
                    _carTypeDropdown(vm),
                    Row(
                      children: [
                        Expanded(child: _textField(label: 'Color', initialValue: vm.carColor, onChanged: (v) => vm.carColor = v)),
                        const SizedBox(width: 16),
                        Expanded(child: _textField(label: 'Mfg Year', initialValue: vm.manufacturingYear, onChanged: (v) => vm.manufacturingYear = v)),
                      ],
                    ),
                    _imagePickerTile('Update RC Photo', vm.rcImage, (s) => vm.pickImage('rcImage', s)),
                    
                    const SizedBox(height: 16),
                    _dateField(context: context, label: 'Insurance Expiry', initialValue: vm.insuranceExpiry, onChanged: (v) => vm.insuranceExpiry = v),
                    _imagePickerTile('Update Insurance Photo', vm.insuranceImage, (s) => vm.pickImage('insuranceImage', s)),
                    
                    const SizedBox(height: 16),
                    _dateField(context: context, label: 'Permit Expiry', initialValue: vm.permitExpiry, onChanged: (v) => vm.permitExpiry = v),
                    _imagePickerTile('Update Permit Photo', vm.permitImage, (s) => vm.pickImage('permitImage', s)),

                    const SizedBox(height: 16),
                    _dateField(context: context, label: 'PUC Expiry', initialValue: vm.pucExpiry, onChanged: (v) => vm.pucExpiry = v),
                    _imagePickerTile('Update PUC Photo', vm.pucImage, (s) => vm.pickImage('pucImage', s)),

                    const SizedBox(height: 24),
                    _sectionTitle('Bank Details'),
                    _textField(label: 'Bank Name', initialValue: vm.bankName, onChanged: (v) => vm.bankName = v),
                    _textField(label: 'Account Holder Name', initialValue: vm.accountHolderName, onChanged: (v) => vm.accountHolderName = v),
                    _textField(label: 'Account Number', initialValue: vm.accountNumber, onChanged: (v) => vm.accountNumber = v),
                    _textField(label: 'IFSC Code', initialValue: vm.ifscCode, onChanged: (v) => vm.ifscCode = v),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final success = await vm.updateProfile();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                            Navigator.pop(context, true);
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _textField({
    required String label, 
    required String initialValue, 
    required Function(String) onChanged,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        obscureText: obscureText,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
          filled: true,
          fillColor: AppColors.grey900,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey800)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.yellow)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField({required BuildContext context, required String label, required String initialValue, required Function(String) onChanged}) {
    final controller = TextEditingController(text: initialValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context, 
            initialDate: initialValue.isNotEmpty ? DateTime.tryParse(initialValue) ?? DateTime.now() : DateTime.now(),
            firstDate: DateTime(1900), 
            lastDate: DateTime(2100)
          );
          if (date != null) {
            final formatted = "\${date.year}-\${date.month.toString().padLeft(2, '0')}-\${date.day.toString().padLeft(2, '0')}";
            controller.text = formatted;
            onChanged(formatted);
          }
        },
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
          filled: true,
          fillColor: AppColors.grey900,
          suffixIcon: const Icon(Icons.calendar_today, color: AppColors.grey500),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey800)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.yellow)),
        ),
      ),
    );
  }

  Widget _carTypeDropdown(EditProfileViewModel vm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: vm.carType.isNotEmpty && vm.carCategoriesList.any((c) => c['_id'] == vm.carType) ? vm.carType : null,
        hint: const Text('Select Car Type', style: TextStyle(color: AppColors.grey500)),
        items: vm.carCategoriesList.map((category) {
          return DropdownMenuItem<String>(
            value: category['_id'],
            child: Text(category['name'], style: const TextStyle(color: AppColors.white)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) vm.setCarCategory(val);
        },
        dropdownColor: AppColors.grey900,
        decoration: InputDecoration(
          labelText: 'Car Type',
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
          filled: true,
          fillColor: AppColors.grey900,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey800)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.yellow)),
        ),
      ),
    );
  }

  Widget _imagePickerTile(String title, File? file, Function(ImageSource) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.grey400))),
          if (file != null) const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          if (file != null) const SizedBox(width: 8),
          PopupMenuButton<ImageSource>(
            color: AppColors.grey900,
            onSelected: onPick,
            itemBuilder: (context) => [
              const PopupMenuItem(value: ImageSource.camera, child: Text('Camera', style: TextStyle(color: AppColors.white))),
              const PopupMenuItem(value: ImageSource.gallery, child: Text('Gallery', style: TextStyle(color: AppColors.white))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.grey800, borderRadius: BorderRadius.circular(8)),
              child: const Text('Upload', style: TextStyle(color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
